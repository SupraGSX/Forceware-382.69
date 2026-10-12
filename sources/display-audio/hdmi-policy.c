/* Independent XP 368.81 implementation. Offsets come from disassembly and
 * same-boot read-only captures, not Nouveau structures. All rates are kHz.
 * HDMI_MAX is a source TMDS character-rate ceiling, not a pixel-clock bypass.
 */
#include "edid-blocks.h"
extern U readCaps(B*,B*,struct Caps*);
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
U sourceModern(U arch,U impl) {
 return (arch==0x120 && (impl==0||impl==4||impl==6)) ||
        (arch==0x130 && (impl==2||impl==4||impl==6||impl==7));
}
static struct Sink sinkCaps(const struct Caps*c){
 struct Sink s={0,0,0,0};
 if(c->status!=GOOD || c->conflict)return s;
 s.valid=1;s.hdmi=c->legacy;
 if(s.hdmi){s.tmds=min(c->tmds,HDMI_MAX);s.caps=c->scdc;}
 return s;
}
struct Sink parseSink(const B*e,U bytes){
 struct Caps c;parseEdid(e,bytes,&c);
 if(bytes<128||!(e[20]&128)){struct Sink s={0,0,0,0};return s;}
 return sinkCaps(&c);
}
U bridge(B *adapter,B *display) {
 U mask=WORD(display,0),type=WORD(display,0x2cf8),proto=WORD(display,0x2cfc);
 if(!mask||(mask&(mask-1))||!(mask&0xffffff00)||type!=2||(proto!=1&&proto!=2&&proto!=5))return 0;
 struct Caps c;readCaps(adapter,display,&c);
 struct Sink s=sinkCaps(&c);
 if(!(display[0x44]&128))s.valid=0;
 U positive=s.valid&&s.hdmi&&(WORD(display,0x2ce0)&32)&&nativeHdmi(display);
 U caps=positive?s.caps:0,rate=0,stock=0,haveStock=0;
 U modern=sourceModern(WORD(adapter,0xb54),WORD(adapter,0xb58));
 if(modern) {
  /* Re-read the same source limit and board adjustment used by 443080.
   * This also removes an earlier HDMI ceiling after a sink change, without
   * retaining private state in an undocumented Windows object. */
  U q[2]={mask,0};
  if(!legacyQuery(WORD(adapter,0x34),0x151,q,8) && q[1] && q[1]<=60000) {
   stock=q[1];
   U f=WORD(display,0x2ce0);
   if(!(f&3)) {
    U scale=(f&4)?2:1,board=WORD(adapter,0xe54);
    if(board<=60000/scale && board*scale>stock)stock=board*scale;
   }
   if(stock<=60000) {haveStock=1;WORD(display,0x18)=stock;}
  }
  /* A failed re-query must not preserve a previous sink's elevated cache. */
  if(!haveStock)WORD(display,0x18)=min(WORD(display,0x18),16500);
  /* Bound a positive HDMI cache until SET and readback both succeed.
   * Preserve existing non-HDMI/DVI query semantics. */
  if(positive)WORD(display,0x18)=min(WORD(display,0x18),min(16500,s.tmds/10));
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
