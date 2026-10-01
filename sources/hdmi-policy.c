/* Independent XP 368.81 implementation. Offsets come from disassembly and
 * same-boot read-only captures, not Nouveau structures. All rates are kHz.
 * HDMI_MAX is a source TMDS character-rate ceiling, not a pixel-clock bypass.
 */
typedef unsigned int U;
typedef unsigned char B;
#ifndef HDMI_MAX
#define HDMI_MAX 594000U
#endif
#define WORD(p,o) (*(U*)((B*)(p)+(o)))
#define MARK 0xa0000000U
extern U __attribute__((stdcall)) rmControl(U,U,U,void*,U);
extern U __attribute__((stdcall)) legacyQuery(U,U,void*,U);
extern U __attribute__((stdcall)) nativeHdmi(B*);
struct Sink { U valid,hdmi,tmds,caps; };
static U min(U a,U b) { return a<b?a:b; }
static U checksum(const B *p) { U s=0;for(U i=0;i<128;i++)s+=p[i];return !(s&255); }
U sourceModern(U arch,U impl) {
 return (arch==0x120 && (impl==0||impl==4||impl==6)) ||
        (arch==0x130 && (impl==2||impl==4||impl==6||impl==7));
}
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
U bridge(B *adapter,B *display) {
 U mask=WORD(display,0),type=WORD(display,0x2cf8),proto=WORD(display,0x2cfc);
 if(!mask||(mask&(mask-1))||!(mask&0xffffff00)||type!=2||(proto!=1&&proto!=2&&proto!=5))return 0;
 struct Sink s=parseSink(display+0x30,WORD(display,0x2c));
 U positive=s.valid&&s.hdmi&&(WORD(display,0x2ce0)&32)&&nativeHdmi(display);
 U caps=positive?s.caps:0,rate=0,stock=0,haveStock=0;
 U modern=sourceModern(WORD(adapter,0xb54),WORD(adapter,0xb58));
 if(modern) {
  /* Re-read the same source limit and board adjustment used by 443080.
   * This also removes an earlier HDMI ceiling after a sink change, without
   * retaining private state in an undocumented Windows object. */
  U q[2]={mask,0};
  if(!legacyQuery(WORD(adapter,0x34),0x151,q,8) && q[1] && q[1]<=600000) {
   stock=q[1];
   U f=WORD(display,0x2ce0);
   if(!(f&3)) {
    U board=WORD(adapter,0xe54)*((f&4)?2:1);
    if(board>stock)stock=board;
   }
   if(stock<=600000) {haveStock=1;WORD(display,0x18)=stock;}
  }
  /* A failed re-query must not preserve a previous sink's elevated cache. */
  if(!haveStock)WORD(display,0x18)=min(WORD(display,0x18),16500);
  if(positive && haveStock)rate=min(s.tmds,stock==16500?HDMI_MAX:stock*10);
  /* Private paired-driver extension: bits 0..2 retain their stock meaning.
   * Unmarked requests to the original RM control remain unchanged. */
  caps=MARK|(rate<<3)|caps;
 }
 U p[3]={WORD(adapter,0x1388),mask,caps};
 U ok=rmControl(WORD(adapter,0xac0),WORD(adapter,0xaec),0x730293,p,12);
 if(ok&&rate) {
  U q[5]={WORD(adapter,0x1388),mask,0,0,0};
  if(rmControl(WORD(adapter,0xac0),WORD(adapter,0xaec),0x73028a,q,20) && q[2]>=25000) {
   /* The Windows validator uses 10 kHz units; RM uses kHz. Query the
    * resolved output to retain any additional RM/VBIOS restriction. */
   WORD(display,0x18)=min(rate,q[2])/10;
  }
 }
 return ok;
}
/* Called inside the existing successful TMDS SCDC-control handler, after it
 * has resolved and class-checked both connector pointers. common+340 holds
 * the chosen OR base; +50 is its original per-link ceiling. common+3f4 is
 * the connector ceiling used by the original validation/reporting callbacks.
 */
U applyClock(B *gpu,B *common,B *tmds,U packed) {
 if((packed&0xff800000U)!=MARK)return 0;
 if(!sourceModern(WORD(gpu,0x6f8),WORD(gpu,0x6f4)))return 0;
 if(!tmds[0x97a])return 0;
 U rate=(packed>>3)&0xfffffU;
 if(rate>HDMI_MAX || (rate && rate<25000))return 0;
 B *resource=(B*)WORD(common,0x340);
 if(!resource||WORD(resource,0x54)!=2)return 0; /* SOR, never DAC or PIOR */
 U original=WORD(resource,0x50);
 if(!original)return 0;
 U limit=original;
 if(rate) {
  /* Replace the proven legacy 165 MHz default only. Any different existing
   * resource restriction is retained as an additional upper bound. */
  limit=min(rate,original==165000?HDMI_MAX:original);
  if(limit>340000 && (packed&5)!=5)limit=340000;
 }
 WORD(common,0x3f4)=limit;
 return limit;
}
