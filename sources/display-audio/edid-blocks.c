#include "edid-blocks.h"
void clearBytes(void *p,U n){B*q=p;for(U i=0;i<n;i++)q[i]=0;}
static void copy(B*d,const B*s,U n){for(U i=0;i<n;i++)d[i]=s[i];}
static U same(const B*a,const B*b,U n){for(U i=0;i<n;i++)if(a[i]!=b[i])return 0;return 1;}
static U sum0(const B*p,U n){U s=0;for(U i=0;i<n;i++)s+=p[i];return !(s&255);}
static U addSad(struct Caps*c,const B*v){
 U format=(v[0]>>3)&15;
 if(!format||(v[0]&128)||!(v[1]&127)||(v[1]&128))return INVALID;
 if(format==1&&(!(v[2]&7)||(v[2]&248)))return INVALID;
 for(U j=0;j<c->count;j++)if(same(c->sads+j*3,v,3))return GOOD;
 if(c->count==SAD_MAX){c->audio_status=OVERFLOW;return GOOD;}
 copy(c->sads+3*c->count,v,3);c->count++;return GOOD;
}
static U vendor(struct Caps*c,const B*v,U n){
 if(n<3)return INVALID;
 if(v[0]==3&&v[1]==12&&!v[2]){
  if(n<5)return INVALID;
  if(c->legacy){if(n!=c->legacy_len||!same(c->vendor,v,n))c->conflict=1;}
  else{copy(c->vendor,v,n);c->legacy_len=n;c->legacy=1;}
 }else if(v[0]==0xd8&&v[1]==0x5d&&v[2]==0xc4){
  if(n<7||v[3]!=1)return INVALID;
  if(c->forum){if(n!=c->forum_len||!same(c->hf,v,n))c->conflict=1;}
  else{copy(c->hf,v,n);c->forum_len=n;c->forum=1;}
 }
 return GOOD;
}
/* primary is the existing first standalone CTA's video/auxiliary projection.
 * Additional collections contribute ONLY audio and HDMI capability data. */
static U collection(struct Caps*c,const B*b,U begin,U end,U primary){
 for(U i=begin;i<end;){
  U tag=b[i]>>5,n=b[i]&31;i++;
  if(n>end-i)return INVALID;
  const B*v=b+i;i+=n;
  if(tag==1){if(!n||n%3)return INVALID;for(U j=0;j<n;j+=3)if(addSad(c,v+j))return INVALID;}
  else if(tag==4){if(n!=3)return INVALID;for(U j=0;j<3;j++)c->speakers[j]|=v[j];}
  else if(tag==3){if(vendor(c,v,n))return INVALID;
   if(primary&&n>=3 && !(v[0]==0xd8&&v[1]==0x5d&&v[2]==0xc4)){
    /* Retain original first-CTA non-HDMI vendor behavior when no HDMI exists. */
    clearBytes(c->primary+0x45,31);copy(c->primary+0x45,v,n);
   }
  }else if(primary&&tag==2){clearBytes(c->primary+2,16);copy(c->primary+2,v,n<16?n:16);}
  else if(tag==7){
   if(!n)return INVALID;
   if(v[0]==0&&n<2)return INVALID;
   if(v[0]==5&&n<3)return INVALID;
   if(v[0]==0x78 && n<2)return INVALID;
   if(v[0]==0x79){
    /* HF-SCDB carries the Forum capability body after two reserved bytes.
     * Normalize just its capability payload, never manufacture HDMI identity. */
    if(n<7||v[1]||v[2])return INVALID;
    B h[31];clearBytes(h,31);h[0]=0xd8;h[1]=0x5d;h[2]=0xc4;
    copy(h+3,v+3,n-3);if(vendor(c,h,n))return INVALID;
   }
   if(primary&&v[0]==0)c->primary[0x6a]=v[1]&127;
   if(primary&&v[0]==5){c->primary[0x68]=v[1]&3;c->primary[0x69]=v[2]&7;}
  }
 }
 return GOOD;
}
U parseEdid(const B*e,U bytes,struct Caps*c){
 clearBytes(c,sizeof(*c));c->status=INVALID;
 if(!e||bytes<128||(bytes&127))return c->status;
 if(bytes>SNAPSHOT_MAX)return c->status=TOO_LARGE;
 if(e[0]||e[7]||e[18]!=1||e[19]>4||!sum0(e,128))return c->status;
 for(U i=1;i<7;i++)if(e[i]!=255)return c->status;
 U blocks=1U+e[126];
 /* Effective count, never allocation size: validate the override's container. */
 if(bytes>=256&&e[126]&&e[128]==2&&e[129]>=3){
  const B*b=e+128;
  if(!sum0(b,128))return c->status;
  if(b[2]>=7&&b[2]<=127&&(b[4]>>5)==7&&(b[4]&31)>=2&&
     5U+(b[4]&31)<=b[2]&&b[5]==0x78&&b[6])blocks=1U+b[6];
 }
 c->blocks=blocks;
 if(blocks>SNAPSHOT_MAX/128)return c->status=TOO_LARGE;
 if(blocks>bytes/128)return c->status=INCOMPLETE;
 U primary=0;
 for(U k=1;k<blocks;k++){
  const B*b=e+128*k;if(!sum0(b,128))return c->status;
  if(b[0]==2){
   U rev=b[1],end=b[2];if(!rev|| (end&&(end<4||end>127)))return c->status;
   U first=!primary;primary=1;c->cta=1;
   if(first){c->primary[0]=rev;if(rev>1)c->primary[1]=b[3];}
   if(rev>=2&&(b[3]&64))c->basic=1;
   if(rev>=3&&end&&collection(c,b,4,end,first))return c->status;
  }else if(b[0]==0x70){
   U length=b[2],end=5+length;
   if(end>=127||!sum0(b+1,length+5))return c->status;
   for(U i=5;i<end;){
    if(end-i<3){
     /* A checksum-valid DisplayID section may end with zero padding shorter
      * than a block header. Preserve strict rejection of a nonzero fragment. */
     for(U j=i;j<end;j++)if(b[j])return c->status;
     break;
    }
    U tag=b[i],n=b[i+2];i+=3;
    if(n>end-i)return c->status;
    if(tag==0x81){c->cta=1;if(collection(c,b,i,i+n,0))return c->status;}
    i+=n;
   }
  }
 }
 if(c->basic){B pcm[3];pcm[0]=9;pcm[1]=7;pcm[2]=1;if(addSad(c,pcm))return c->status;}
 if(c->audio_status==OVERFLOW){c->count=0;clearBytes(c->sads,45);clearBytes(c->speakers,3);}
 if(c->legacy&&!c->conflict){
  U rate=165000;
  if(c->legacy_len>=7&&c->vendor[6])rate=c->vendor[6]*5000U;
  if(c->forum&&c->hf[4])rate=c->hf[4]*5000U;
  if(c->forum&&(c->hf[5]&128)){c->scdc=4;if(rate>340000)c->scdc|=1;if(c->hf[5]&8)c->scdc|=2;}
  if((c->scdc&5)!=5&&rate>340000)rate=340000;
  c->tmds=rate;
 }
 return c->status=GOOD;
}
void audioSummary(const struct Caps*c,B*out){
 clearBytes(out,107);
 if(c->status!=GOOD)return;
 copy(out,c->primary,107);
 clearBytes(out+0x12,48);clearBytes(out+0x42,3);out[1]&=~64U;
 if(c->audio_status==GOOD){
  copy(out+0x12,c->sads,c->count*3);copy(out+0x42,c->speakers,3);
  if(c->basic)out[1]|=64;
 }
 if(c->cta && out[0]<3)out[0]=3;
 if(c->legacy){clearBytes(out+0x45,31);if(!c->conflict)copy(out+0x45,c->vendor,c->legacy_len);}
}
