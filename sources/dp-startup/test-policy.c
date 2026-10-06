typedef unsigned int u32;
extern u32 best_pair(u32,u32,u32),query_pair(u32,u32,u32,u32),choose_depth(u32,u32,u32,u32);
static void stop(u32 c) { __asm__ volatile("int $0x80"::"a"(1),"b"(c)); }
void _start(void) {
 u32 mask,r,l;
 const u32 rates[]={6,10,20,30},lanes[]={1,2,4};
 for(mask=0;mask<256;mask++)for(r=0;r<4;r++)for(l=0;l<3;l++){
  u32 trained=best_pair(mask,rates[r],lanes[l]);
  if(query_pair(mask,rates[r],lanes[l],1)!=trained)stop(1);
  if(query_pair(mask,rates[r],lanes[l],0)!=(mask?trained:(rates[r]<<8)|lanes[l]))stop(2);
 }
 if(query_pair(0,0,4,0)||query_pair(0,30,3,0)||query_pair(0,31,4,0))stop(3);
 if(query_pair(0x40,30,4,1)!=0x1404)stop(4); /* HBR3 receiver, GPU trained HBR2 */
 if(query_pair(0,30,4,1)!=0)stop(5); /* Failed active probe cannot advertise HBR3. */
 if(choose_depth(52660,20,4,4)!=2)stop(6); /* Posted issue EDID: 12 -> 8 bpc. */
 if(choose_depth(54350,20,4,3)!=3)stop(7);
 if(choose_depth(31975,10,4,3)!=2)stop(8);
 stop(0);
}
