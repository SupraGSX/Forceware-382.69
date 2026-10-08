/* Bounded automatic native DisplayPort preference. No hardware writes, allocation,
 * per-monitor state, table mutation or mode-validation bypass. Only the two verified
 * display+0x234 timing-table callers may use this wrapper. */
typedef unsigned int U; typedef unsigned char B;
#include "dp-policy.c"
static U min(U a,U b){return a<b?a:b;}
static U base_valid(const B*e,U bytes){
 if(bytes<128 || bytes>512 || (bytes&127) || e[0] || e[7] || !(e[20]&128))return 0;
 for(U i=1;i<7;i++)if(e[i]!=255)return 0;
 U sum=0;for(U i=0;i<128;i++)sum+=e[i];
 return !(sum&255) && e[18]==1 && (e[19]==3 || e[19]==4) && (e[24]&2);
}
/* Only base preferred-DTD data is needed here. Some DP objects intentionally
 * retain only the 128-byte base block. Link limits come from native successful
 * training records, never from a CTA HDMI block or missing extensions. */
#define W(p,o) (*(U*)((B*)(p)+(o)))
#define H(p,o) (*(unsigned short*)((B*)(p)+(o)))
extern U __attribute__((stdcall)) previous_selector(void*,void*,U,U*,U*,U*);
extern U __attribute__((stdcall)) native_cap(void*,void*,U,U*,U*,U*,U);
static U equal(const U*a,const U*b){for(U i=0;i<8;i++)if(a[i]!=b[i])return 0;return 1;}
U __attribute__((stdcall)) dp_output_selector(B*source,U*table,U closest,U*out,U*flags,U*type){
 if(!source || !table || !out)return previous_selector(source,table,closest,out,flags,type);
 U incomingFlags=flags?*flags:0;
 U result=previous_selector(source,table,closest,out,flags,type);
 /* Exact/custom source timings, errors and closest-match requests stay stock. */
 if(result!=2 || closest || !source || !table || !out || !*table || *table>64)return result;
 B*d=(B*)table-0x234;U mask=W(d,0),limit=W(d,0x18),proto=W(d,0x2cfc);
 if(!mask || (mask&(mask-1)) || (mask&255) || W(d,0x2cf8)!=2 ||
    (proto!=8 && proto!=9))return result;
 U rate=W(d,0x2d30),lanes=W(d,0x2d34);
 if(!valid(rate,lanes))return result;
 U pair=best_pair(W(d,0x2d00),rate,lanes);
 if(!pair || !limit || limit>108000U || !base_valid(d+0x30,W(d,0x2c)))return result;
 rate=pair>>8;lanes=pair&255;
 /* Admission at RGB8 matches the installed DP policy: the actual mode chooser
  * retains requested depth when it fits, reduces higher depth to 8 if needed,
  * and rejects insufficient capacity. Do not independently set depth or train.
  * Divide only bounded quantities and include the same integer 0.5% margin. */
 U capacity=rate*lanes*21600U/24U;
 U upper=capacity*200U/201U;
 while(upper<capacity && depth_fits(upper+1,rate,lanes,2))upper++;
 limit=min(limit,upper);
#ifdef TEST_MAX_CLOCK
 limit=min(limit,TEST_MAX_CLOCK);
#endif
 if(limit<=16500)return result;
 /* Require the actual progressive base preferred DTD, not an inferred
  * resolution, custom entry, unrelated refresh or stale native dimensions. */
 const B*e=d+0x30;U preferred=H(e,54);
 U width=e[56]|((U)(e[58]&240)<<4),height=e[59]|((U)(e[61]&240)<<4);
 if(!preferred || preferred>limit || (e[71]&0xe1) || !width || !height ||
    W(d,8)!=(height<<16|width))return result;
 /* Match the current raw DTD geometry, not just its clock and dimensions.
  * A cached parsed entry can otherwise survive a changed porch/blanking DTD.
  * Unusual border or non-separate-sync modes keep the stock result. */
 U hb=e[57]|((U)(e[58]&15)<<8),vb=e[60]|((U)(e[61]&15)<<8);
 U hf=e[62]|((U)(e[65]&192)<<2),hs=e[63]|((U)(e[65]&48)<<4);
 U vf=(e[64]>>4)|((U)(e[65]&12)<<2),vs=(e[64]&15)|((U)(e[65]&3)<<4);
 if((e[71]&24)!=24 || e[69] || e[70] || !hb || !vb || !hs || !vs ||
    hf+hs>hb || vf+vs>vb)return result;
 U candidate[8],cf=incomingFlags,ct=0;
 U cr=native_cap(source,table,closest,candidate,&cf,&ct,limit);
 if(cr!=2 || ct!=0x90001 || candidate[0]!=preferred ||
    candidate[1]!=(height<<16|width) || width<H(source,4) || height<H(source,6) ||
    H(candidate,8)!=width+hb || H(candidate,14)!=height+vb ||
    H(candidate,10)!=hf || H(candidate,12)!=hs ||
    H(candidate,16)!=vf || H(candidate,18)!=vs ||
    ((B*)candidate)[24]!=(U)!(e[71]&2) ||
    ((B*)candidate)[25]!=(U)!(e[71]&4))return result;
 /* Cross-check actual rounded refresh as well as table metadata. The bounded
  * clock keeps the arithmetic within32bits even with16-bit totals. */
 U pixels=(U)H(candidate,8)*H(candidate,14);
 U hz=(candidate[0]*10000U+pixels/2)/pixels;
 if(hz!=H(source,10))return result;
 /* Check selected timing against the bounded current parsed table, including
  * the source's requested refresh. Native may otherwise pick a 50 Hz timing
  * as the low-bandwidth alternative for a 60 Hz request. */
 U found=0;
 for(U i=0;i<*table;i++){
  U*entry=table+1+i*21;
  if(entry[2]==ct && (entry[1]&65535)==H(source,10) && equal(candidate,entry+11)) {found=1;break;}
 }
 if(!found)return result;
 for(U i=0;i<8;i++)out[i]=candidate[i];
 if(flags)*flags=cf;if(type)*type=ct;
 return cr;
}
