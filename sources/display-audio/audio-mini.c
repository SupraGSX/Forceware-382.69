#include "edid-blocks.h"
#define W(p,o) (*(U*)((B*)(p)+(o)))
extern U __attribute__((stdcall)) rmControl(U,U,U,void*,U);
extern void* __attribute__((stdcall)) allocatePool(U,U,U);
extern void __attribute__((stdcall)) freePool(void*);
extern B* __attribute__((stdcall)) findDisplay(B*,U);
extern U __attribute__((stdcall)) nativeSummary(const B*,U,B*);
extern U __attribute__((stdcall)) nativeRate(U);
extern U __attribute__((stdcall)) nativeMulDiv(U,U,U);
static U equal(const B*a,const B*b,U n){for(U i=0;i<n;i++)if(a[i]!=b[i])return 0;return 1;}
/* RM copies into a per-invocation nonpaged allocation. No borrowed cache pointer,
 * no added lock, no DDC retry/sleep, no global mutable state. Pointer high=0 is
 * exactly the existing 233070 native request ABI. Returned size is the full size. */
U readCaps(B*adapter,B*display,struct Caps*c){
 clearBytes(c,sizeof(*c));c->status=UNAVAILABLE;
 if(!adapter||!display)return c->status;
 U mask=W(display,0);if(!mask||(mask&(mask-1)))return c->status;
 B*e=allocatePool(0,SNAPSHOT_MAX,0x4144564e);if(!e)return c->status;
 clearBytes(e,SNAPSHOT_MAX);
 U q[6]={W(adapter,0x1388),mask,(U)e,0,SNAPSHOT_MAX,0};
 if(rmControl(W(adapter,0xac0),W(adapter,0xaec),0x730241,q,24)){
  if(q[4]>SNAPSHOT_MAX)c->status=TOO_LARGE;
  else if(q[4]<128 || W(display,0x2c)<128 || (q[4]<(W(display,0x2c)<512?W(display,0x2c):512)) || !equal(e,display+0x30,W(display,0x2c)<512?W(display,0x2c):512))c->status=INCOMPLETE;
  else parseEdid(e,q[4],c);
 }
 freePool(e);return c->status;
}
/* Only the 782E/B audio-consumer projection. Raw EDID API remains 256 bytes. */
U __attribute__((stdcall)) parsedAudio(B*adapter,const B*raw,U bytes,B*out){
 (void)bytes;struct Caps c;
 U status=readCaps(adapter,(B*)raw-0x30,&c);
 audioSummary(&c,out);
 return status?0x80000100U|status:(c.audio_status?0x80000200U|c.audio_status:0);
}
/* The native 782E/11 discovery query used by the ELD caller. Retain its field
 * encoding; this is a gate, not a synthesized list of supported combinations. */
U __attribute__((stdcall)) audioGate(B*a,U command,U ni,const U*in,U no,U*out){
 (void)command;
 if(!a||!in||ni!=8||!out||no!=4)return 0;
 U mask=in[1]; /* Capture before an aliased output write. */
 if(!mask||(mask&(mask-1)))return 0;
 B*d=findDisplay(a,mask);if(!d)return 0;
 struct Caps c;U result=0;
 if(readCaps(a,d,&c)==GOOD&&c.audio_status==GOOD){
  if(c.basic)result=0xe4001;
  for(U i=0;i<c.count;i++){
   const B*v=c.sads+3*i;U f=(v[0]>>3)&15;
   if(f==15)continue; /* Native source representation cannot encode extended formats. */
   result|=f|((U)v[1]<<18);
   if(f==1)result|=(v[2]&7)<<14;
  }
 }
 *out=result;return 1;
}
/* Native source/timing intersection, preserving each distinct sink SAD.
 * 442210 still owns enable/clear state and output eligibility. Both native
 * 731148 and 103E0 calculations remain; unsupported format15 is not invented. */
U __attribute__((stdcall)) audioSource(B*a,B*out,B*d,U clock,U transport){
 if(!a||!out||!d)return 2;
 clearBytes(out,84);W(out,4)=W(d,0);
 struct Caps c;U status=readCaps(a,d,&c);
 if(status||c.audio_status)return 2;
 U maxRate=0,count=0,haveBudget=0,budget=0;
 for(U i=0;i<c.count;i++){
  const B*v=c.sads+i*3;U f=(v[0]>>3)&15,rates=v[1]&127,ch=(v[0]&7)+1;
  if(!f||f==15)continue;
  if(f==1){
   if(!haveBudget){
    U q[3]={W(a,0x1388),W(d,0),0};
    if(!clock||clock>429496U||!rmControl(W(a,0xac0),W(a,0xaec),0x731148,q,12))return 2;
    haveBudget=1;budget=q[2];
   }
   /* A zero packet budget cannot authorize PCM, even if integer rounding
    * makes an individual native timing calculation return zero. */
   if(!budget)continue;
   /* Check every advertised sample rate, not just a coalesced format maximum. */
   for(U bit=1;bit<=64;bit<<=1)if(rates&bit){
    U needed=nativeMulDiv(transport&65535,nativeRate(bit),clock*10000U);
    if(ch<=2)needed=(needed>>2)+((needed&3)!=0);
    if(needed>budget)rates&=~bit;
   }
  }
  if(!rates)continue;
  U descriptor=0x80000000U|f|((ch-1)<<25)|(rates<<17)|
    (f==1?(v[2]&7)<<14:(U)v[2]<<4);
  /* Exact deduplication again after intersection may make two tuples equal. */
  U same=0;for(U j=0;j<count;j++)if(W(out,12+j*4)==descriptor)same=1;
  if(same)continue;
  if(count==SAD_MAX){clearBytes(out,84);W(out,4)=W(d,0);return 2;}
  W(out,12+4*count++)=descriptor;
  for(U bit=1;bit<=64;bit<<=1)if((rates&bit)&&bit>maxRate)maxRate=bit;
 }
 W(out,8)=count;U ordinal=0;while(maxRate){ordinal++;maxRate>>=1;}
 W(out,0x4c)=ordinal;W(out,0x50)=c.speakers[0]&127;
 if(c.basic&&!c.speakers[0])W(out,0x50)=1;
 return 0;
}
/* Refresh only: retain native first-CTA summary semantics through a private,
 * bounded first-CTA projection. Later collections affect HDMI identity only.
 * This call remains BEFORE the native HDMI monitor blacklist. No mode cache
 * or raw EDID is rearranged, and audio queries above do not use this summary. */
U __attribute__((stdcall)) refreshSummary(B*a,const B*raw,U bytes,B*out){
 struct Caps c;B safe[256];clearBytes(safe,256);
 if(!out)return nativeSummary(raw,bytes,0);
 clearBytes(out,107);
 U status=readCaps(a,(B*)raw-0x30,&c);
 if(status)return 0x80000000U|status;
 /* Preserve the first collection's unrelated metadata, with bounded fields.
 * These fields are identical to native output for canonical first-CTA input. */
 for(U i=0;i<107;i++)out[i]=c.primary[i];
 /* Native discovery still expects first-CTA audio. Its source/ELD users have
  * separate complete-cache queries, so no cross-block audio aggregation here. */
 if(bytes>=128&&bytes<=512){
  U limit=c.blocks*128;if(limit>bytes)limit=bytes;
  for(U k=128;k+128<=limit;k+=128)if(raw[k]==2){
   const B*b=raw+k;B*t=safe+128;t[0]=2;t[1]=b[1];t[3]=b[3];U end=b[2],pos=4;
   if(b[1]>=3&&end>=4&&end<=127)for(U i=4;i<end;){
    U tag=b[i]>>5,n=b[i]&31;i++;if(n>end-i)break;
    U keep=n;
    if(tag==2&&keep>16)keep=16;
    if(tag==7&&n&&b[i]==0)keep=2;
    if(tag==7&&n&&b[i]==5)keep=3;
    if(keep>n||pos+1+keep>127)break;
    t[pos++]=(tag<<5)|keep;for(U j=0;j<keep;j++)t[pos++]=b[i+j];i+=n;
   }
   t[2]=pos;nativeSummary(safe,256,out);break;
  }
 }
 if(c.legacy){clearBytes(out+0x45,31);if(!c.conflict){
   for(U i=0;i<c.legacy_len;i++)out[0x45+i]=c.vendor[i];
   if(out[0]<3)out[0]=3;
 }}
 return c.cta?0:0x80000000U;
}

/* 782E/12 DP capability bit 0x100 is consumed as sink-audio presence at
 * nv4_disp!486E8, although stock derives it only from first-CTA basic audio.
 * Keep the original DP/eDP eligibility gates and all other output bits. */
U __attribute__((stdcall)) sinkAudio(B*a,B*d){
 struct Caps c;
 if(readCaps(a,d,&c)!=GOOD||c.audio_status!=GOOD)return 0;
 for(U i=0;i<c.count;i++){
  U f=(c.sads[3*i]>>3)&15;
  if(f&&f<15)return 1;
 }
 return 0;
}
