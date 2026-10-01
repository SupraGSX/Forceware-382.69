/* XP368.81-specific bridge. All Windows offsets and calling conventions are
 * established from this binary; no Nouveau structures are used. */
typedef unsigned int U;
typedef unsigned char B;
extern U __attribute__((stdcall)) rmControl(U client,U display,U cmd,void *params,U bytes);
static int goodblock(const B *p) { U s=0; for(U i=0;i<128;i++)s+=p[i]; return !(s&255); }
U sinkCaps(const B *e,U bytes) {
 if(bytes<128 || bytes>512 || (bytes&127) || e[0] || e[7] || !goodblock(e))return 0;
 for(U i=1;i<7;i++)if(e[i]!=255)return 0;
 U caps=0,hdmi=0;U count=e[126];if(count>bytes/128-1)count=bytes/128-1;
 for(U k=1;k<=count;k++) {
  const B *b=e+k*128;if(!goodblock(b))return 0;
  if(b[0]!=2 || b[1]<3)continue;
  U end=b[2];if(!end)continue;if(end<4||end>127)return 0;
  for(U i=4;i<end;) {
   U tag=b[i]>>5,n=b[i]&31;i++;
   if(i+n>end)return 0;
   if(tag==3 && n>=3) {
    const B *v=b+i;
    if(v[0]==3 && v[1]==12 && v[2]==0)hdmi=1;
    if(n>=6 && v[0]==0xd8 && v[1]==0x5d && v[2]==0xc4 && v[3]==1) {
     U f=0;if(v[5]&128) {f=4;if(v[4]>68)f|=1;if(v[5]&8)f|=2;}
     caps=f;
    }
   }
   i+=n;
  }
 }
 return hdmi?caps:0;
}
U bridge(B *adapter,B *display) {
 U mask=*(U*)display;
 if(!mask || (mask&(mask-1)) || !(mask&0xffffff00))return 0;
 /* Only Windows' already-discovered TMDS flat-panel subtype, observed here.
  * DP (8/9) and analog paths are deliberately outside this experiment. */
 if(*(U*)(display+0x2cf8)!=2 || *(U*)(display+0x2cfc)!=2)return 0;
 U caps=sinkCaps(display+0x30,*(U*)(display+0x2c));
 U p[3]={*(U*)(adapter+0x1388),mask,caps};
 return rmControl(*(U*)(adapter+0xac0),*(U*)(adapter+0xaec),0x730293,p,12);
}
