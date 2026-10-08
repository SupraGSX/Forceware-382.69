typedef unsigned int U; typedef unsigned char B;
#define HDMI_MAX 594000U
struct Sink { U valid,hdmi,tmds,caps; };
static U min(U a,U b) { return a<b?a:b; }
static U checksum(const B *p) { U s=0;for(U i=0;i<128;i++)s+=p[i];return !(s&255); }
struct Sink parseSink(const B *e,U bytes) {
 struct Sink s={0,0,0,0};U legacy=0,forum=0,legacyRate=165000,hfRate=0,hfFlags=0;
 if(bytes<128||bytes>512||(bytes&127)||e[0]||e[7]||!checksum(e)||!(e[20]&128))return s;
 for(U i=1;i<7;i++)if(e[i]!=255)return s;
 if(e[126]>bytes/128-1)return s;
 for(U k=1;k<=e[126];k++) {
  const B *b=e+k*128;if(!checksum(b))return s;
  if(b[0]!=2)continue;
  if(b[1]<3)continue;
  U end=b[2];if(!end)continue;if(end<4||end>127)return s;
  for(U i=4;i<end;) {
   U tag=b[i]>>5,n=b[i]&31;i++;
   if(i+n>end)return s;
   const B*v=b+i;
   if(tag==3&&n>=3) {
    if(v[0]==3&&v[1]==12&&v[2]==0) {
     if(n<5||legacy++)return s;
     if(n>=7&&v[6])legacyRate=v[6]*5000U;
    }
    if(v[0]==0xd8&&v[1]==0x5d&&v[2]==0xc4) {
     if(n<6||v[3]!=1||forum++)return s;
     hfRate=v[4]*5000U;hfFlags=v[5];
    }
   }
   i+=n;
  }
 }
 s.valid=1;s.hdmi=legacy;
 if(!legacy)return s;
 s.tmds=hfRate?hfRate:legacyRate;
 if(forum&&(hfFlags&128)) {
  s.caps=4;if(hfRate>340000)s.caps|=1;if(hfFlags&8)s.caps|=2;
 }
 /* Above 340 MHz both SCDC and a stated high TMDS rate are required. */
 if((s.caps&5)!=5)s.tmds=min(s.tmds,340000);
 s.tmds=min(s.tmds,HDMI_MAX);
 return s;
}
