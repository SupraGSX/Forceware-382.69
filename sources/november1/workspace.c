/* Reserve firmware workspace for the validated GP107/GP108 request shapes. */
typedef unsigned int U;typedef unsigned char B;typedef unsigned short H;
#define S __attribute__((stdcall))
#define D(p,o) (*(U*)((B*)(p)+(o)))
typedef U(S*Alloc)(void*,void*,void*,void*,void*);
extern U S allocate531(U,Alloc,U*,void*,void*,B*,void*,void*);
U S allocate591(U provider,Alloc fn,U*d,void*g,void*p,B*a,void*h,void*t){
 if(g&&D(g,0x714)==0x130&&(D(g,0x710)==7||D(g,0x710)==8)&&D(g,0x1674)==(U)p&&
 D(g,0x16e0)&&D((void*)D(g,0x16e0),0x1bc)==provider&&d&&d[0]&&d[0]==d[4]&&
 d[1]==4&&d[5]==4&&d[2]==16&&d[6]==16&&!d[3]&&!d[7]&&*(H*)a==16){
  B*c=a-8,*r=(B*)d[0];
  U n=0;
  if(c[1]==28&&r[0]==c[0]&&!r[1]&&!r[2]&&r[13]<=1){
   U k=r[12],get=r[13],marker=D(c,4);
   if(c[0]==19&&marker==0x37410380&&k==7)n=784;
   else if(c[0]==20&&marker==0x37410580&&!get){if(k==0)n=16;else if(k==1)n=32;else if(k==2)n=80;}
   else if(c[0]==24&&marker==0x37411880&&!get){if(k==0)n=32;else if(k==1)n=48;else if(k==2)n=64;}
  }
  if(n){*(H*)a=(H)(16+n);U status=fn(g,p,a,h,t);*(H*)a=16;return status;}
 }
 return allocate531(provider,fn,d,g,p,a,h,t);
}
