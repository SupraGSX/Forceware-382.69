/* DP SST policy. Rate is in 270 Mbps units; pixel clock in 10 kHz units.
 * Each bitmap bit records a successful complete training of that exact pair.
 * This is a new policy adapter for the observed 368.81 ABI, not Nouveau code. */
typedef unsigned int u32;
static u32 valid(u32 rate,u32 lanes) {
 return (rate==6 || rate==10 || rate==20 || rate==30) &&
        (lanes==1 || lanes==2 || lanes==4);
}
u32 best_pair(u32 passed,u32 receiver_rate,u32 receiver_lanes) {
 u32 best=0,capacity=0,i;
 for(i=0;i<8;i++) {
  u32 rate,lanes;
  if(i<6) { rate=(i&1)?10:6; lanes=1U<<(i>>1); }
  else { rate=(i==6)?20:30; lanes=4; }
  if((passed&(1U<<i)) && rate<=receiver_rate && lanes<=receiver_lanes && rate*lanes>capacity) {
   capacity=rate*lanes; best=(rate<<8)|lanes;
  }
 }
 return best;
}
u32 depth_fits(u32 clock,u32 rate,u32 lanes,u32 depth) {
 u32 bpc,capacity;
 if(!valid(rate,lanes) || !clock) return 0;
 switch(depth) {
  case 0:case 2:bpc=8;break;
  case 1:bpc=6;break;
  case 3:bpc=10;break;
  case 4:bpc=12;break;
  case 5:bpc=16;break;
  default:return 0;
 }
 capacity=rate*lanes*21600U;
 /* Bound first so neither the margin addition nor a hostile clock can wrap. */
 if(clock>capacity) return 0;
 return clock+clock/200U <= capacity/(3U*bpc);
}
u32 choose_depth(u32 clock,u32 rate,u32 lanes,u32 requested) {
 if(depth_fits(clock,rate,lanes,requested)) return requested?requested:2;
 if(requested>=3 && requested<=5 && depth_fits(clock,rate,lanes,2)) return 2;
 return 0;
}
u32 __attribute__((stdcall)) select_pair(u32 pdev,u32 clock,u32 rate,u32 lanes,u32 depth,u32 head,u32 *out_rate,u32 *out_lanes) {
 (void)pdev;(void)head;
 if(!out_rate || !out_lanes) return 0;
 *out_rate=0;*out_lanes=0;
 if(!depth_fits(clock,rate,lanes,depth)) return 0;
 /* rate and lanes are one pair supplied by best_pair, never independent maxima. */
 *out_rate=rate;*out_lanes=lanes;
 return 1;
}
