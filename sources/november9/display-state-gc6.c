/* Preserve the native display-state lifecycle and translate owned firmware state views. */
typedef unsigned int U;typedef unsigned char B;
#define S __attribute__((stdcall))
#define D(p,o) (*(U*)((B*)(p)+(o)))
extern U marker634(void);
extern void* S native_copy634(void*,const void*,U);
static B* raw(B*d,U i){return (B*)D(d,0xf84+32*i);}
static int owned(B*d,U i){B*p=raw(d,i),*m=(B*)D(d,0xf70+32*i);return p&&m&&(U)p<=0xffffe347u&&D(m,0x20)>=0x1cb8;}
static int admitted(B*g,B*d,B*c,B*src){
 B *p,*q;U i;
 if(!g||!d||!c)return 0;
 p=(B*)D(g,0x16e0);if(!p||D(p,0x1bc)!=marker634())return 0;
 p=(B*)D(d,0xf2c);if(!p)return 0;p=(B*)D(p,0xe0);if(!p)return 0;
 p=(B*)D(p,0x78);if(!p)return 0;p=(B*)D(p,0x1c0);if(!p||D(p,0xc)!=0x1698d1a)return 0;
 if(D(d,0xc0c)>4)return 0;i=d[0xfb0];if(i>1||!owned(d,i)||raw(d,i)!=src)return 0;
 if(i==0&&!owned(d,1))return 0;
 p=raw(d,0);q=raw(d,1);if(p&&q){if((U)p>0xffffe347u||(U)q>0xffffe347u)return 0;if((U)p<(U)q?(U)p+0x1cb8>(U)q:(U)q+0x1cb8>(U)p)return 0;}
 return 1;
}
static void convert(B*d,B*c,B*src){
 B*old=(B*)D(c,0xffc),*dst=src+0x1000;U i;
 if(!(owned(d,0)&&old==raw(d,0)+0x1000)&&!(owned(d,1)&&old==raw(d,1)+0x1000))old=c+0xc0;
 if(dst!=old)native_copy634(dst,old,0xcb8);
 /* Same exact391-to-XP field ranges as the existing snapshot adapter. */
 for(i=0;i<4;i++){native_copy634(dst,src,0xf0);src+=0x108;dst+=0xf0;native_copy634(dst,src,0x2c);src+=0x44;dst+=0x2c;}
 for(i=0;i<4;i++){native_copy634(dst,src,0x8c);src+=0xa4;dst+=0x8c;native_copy634(dst,src,0x10);src+=0x1c;dst+=0x10;}
 native_copy634(dst,src,0x1d8);
}
void* S inline634(B*g,B*d,B*c,B*dst,B*src,U n){
 if(c&&n==0xcb8&&dst==c+0xc0&&admitted(g,d,c,src)){
  void*r;convert(d,c,src);r=native_copy634(dst,src+0x1000,0xcb8);D(c,0xffc)=(U)(src+0x1000);return r;
 }
 return native_copy634(dst,src,n);
}
void* S handoff634(B*g,B*d,B*c,B*dst,B*src,U n){
 if(n==0xcb8&&d&&d[0xfb0]==0&&dst==raw(d,1)&&admitted(g,d,c,src)){
  /* Enclosing native unload owns stop/lifecycle; retain its status. Preserve both views. */
  native_copy634(dst,src,0xa0c);native_copy634(dst+0x1000,src+0x1000,0xcb8);return dst+0x1000;
 }
 return native_copy634(dst,src,n);
}
