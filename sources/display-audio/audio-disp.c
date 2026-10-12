typedef unsigned int U;typedef unsigned char B;
#define W(p,o) (*(U*)((B*)(p)+(o)))
extern U __attribute__((stdcall)) deviceControl(U,U,void*,U,void*,U,U*);
static void zero(B*p,U n){for(U i=0;i<n;i++)p[i]=0;}
/* Called after native ELD construction, without promoting any enable flags. */
void validateEld(B*frame,B*packet){
 if(!packet)return;
 B*parsed=(B*)W(frame,0x20);
 U bad=!parsed||W(parsed,4)!=0;
 if(frame[0x15]&&frame[0x16]&&frame[0x17]&&!frame[0x14])
  bad|=W(frame,0x3c)!=0; /* 7829/11 returned status. */
 if((W(packet,0x70)&2) && (bad||!(packet[0x11]>>4)||W(packet,8)>96)){
  W(packet,0x70)&=~2U;W(packet,8)=0;W(packet,0x6c)=0;zero(packet+12,96);
 }
}
/* Failure after allocation: clear only current request's ELD-valid bit, retain
 * present/enable intent, submit once, then original cleanup frees allocations.
 * Display mode/link state is not touched. A later successful update republishes.
 */
void failedEld(B*frame,B*packet){
 if(!packet)return;
 B*a=(B*)W(frame,0xac);if(!a)return;
 zero(packet,120);W(packet,0)=W(a,0xe4);W(packet,4)=W(frame,0xb0);
 W(packet,0x70)=(frame[0x15]?1:0)|(frame[0x17]?4:0);
 U returned=0;deviceControl(W(a,8),0x232fd4,packet,120,0,0,&returned);
}
