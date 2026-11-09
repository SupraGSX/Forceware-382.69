/* Convert supported monitor timings to the native XP row format. */
typedef unsigned int U;typedef unsigned short W;typedef unsigned char B;
#define S __attribute__((stdcall))
#define D(p,o) (*(const U*)((const B*)(p)+(o)))
#define H(p,o) (*(const W*)((const B*)(p)+(o)))
extern void S nativeTiming643(const W*,B*);
U S convert643(const B*n,B*r,U origin,U seq){
 W t[18];U i,h,v,ht,vt,hfp,vfp,hs,vs;
 if(!n||!r||H(n,24)||H(n,2)||H(n,14)||H(n,48)!=1||H(n,10)>1||H(n,22)>1)return 0;
 h=H(n,0);v=H(n,12);ht=H(n,8);vt=H(n,20);hfp=H(n,4);hs=H(n,6);vfp=H(n,16);vs=H(n,18);
 if(!h||!v||!hs||!vs||!D(n,28)||!H(n,36)||h+hfp+hs>=ht||v+vfp+vs>=vt)return 0;
 if(origin!=9&&origin!=13)return 0;if(!seq||seq>(origin==13?127u:64u))return 0;
 for(i=0;i<18;i++)t[i]=0;
 t[0]=h;t[1]=v;t[2]=0;t[3]=H(n,36);t[4]=ht;t[5]=h;t[6]=h+hfp;t[7]=h+hfp+hs;t[8]=ht;t[9]=vt;t[10]=v;t[11]=v+vfp;t[12]=v+vfp+vs;t[13]=vt;*(U*)(t+14)=D(n,28);t[16]=H(n,10)?0:1;t[17]=H(n,22)?0:1;
 for(i=0;i<84;i++)r[i]=0;
 *(W*)r=h;*(W*)(r+2)=v;*(U*)(r+4)=H(n,36);*(U*)(r+8)=(origin<<16)|seq;
 nativeTiming643(t,r+44);for(i=0;i<32;i++)r[12+i]=r[44+i];if(origin==13)r[80]=seq;
 return 1;
}
