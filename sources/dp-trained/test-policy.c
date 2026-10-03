typedef unsigned int u32;
extern u32 best_pair(u32,u32,u32),depth_fits(u32,u32,u32,u32),choose_depth(u32,u32,u32,u32);
extern u32 __attribute__((stdcall)) select_pair(u32,u32,u32,u32,u32,u32,u32*,u32*);
static const u32 rates[8]={6,10,6,10,6,10,20,30};
static const u32 lanes[8]={1,1,2,2,4,4,4,4};
static const u32 bpc[6]={8,6,8,10,12,16};
static void exitcode(u32 code) { __asm__ volatile("int $0x80"::"a"(1),"b"(code)); for(;;); }
void _start(void) {
 u32 mask,r,l,i,d,c,tests=0;
 for(mask=0;mask<256;mask++) for(r=0;r<=31;r++) for(l=0;l<=5;l++) {
  u32 expected=0,best=0;
  for(i=0;i<8;i++) if((mask&(1U<<i)) && rates[i]<=r && lanes[i]<=l && rates[i]*lanes[i]>best) {best=rates[i]*lanes[i];expected=(rates[i]<<8)|lanes[i];}
  if(best_pair(mask|0xffff0000U,r,l)!=expected) exitcode(11);
  tests++;
 }
 for(i=0;i<8;i++) for(d=0;d<8;d++) {
  r=rates[i];l=lanes[i];
  for(c=0;c<150000;c++) {
   u32 expected=d<6 && c && ((unsigned long long)c+c/200U)*(3U*bpc[d]) <= (unsigned long long)r*l*21600U;
   if(depth_fits(c,r,l,d)!=expected) exitcode(12);
   u32 chosen=expected?(d?d:2):((d>=3 && d<=5 && ((unsigned long long)c+c/200U)*24<=r*l*21600U && c)?2:0);
   if(choose_depth(c,r,l,d)!=chosen) exitcode(13);
   tests++;
  }
  if(depth_fits(0xffffffffU,r,l,d)) exitcode(14);
 }
 if(best_pair(0x18,30,4)!=0x604) exitcode(15); /* RBRx4 beats HBRx2; never mix HBRx4 */
 if(choose_depth(31975,10,4,3)!=2 || choose_depth(54350,20,4,3)!=3 || choose_depth(54350,10,4,3)!=0) exitcode(16);
 if(depth_fits(14835,6,4,3)!=1 || choose_depth(31975,6,4,3)!=0) exitcode(17);
 r=99;l=99;if(select_pair(0,6500,10,4,3,0,&r,&l)!=1 || r!=10 || l!=4) exitcode(18);
 r=99;l=99;if(select_pair(0,54350,10,4,2,0,&r,&l)!=0 || r || l) exitcode(19);
 if(select_pair(0,6500,10,4,2,0,0,&l)) exitcode(20);
 const char msg[]="PASS: compiled i386 policy, 49152 bitmap/cap cases and 9600000 depth/clock cases, overflow and ABI checks\n";
 __asm__ volatile("int $0x80"::"a"(4),"b"(1),"c"(msg),"d"(sizeof(msg)-1):"memory");
 exitcode(0);
}
