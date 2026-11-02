/* GP107/GP108 legacy PSI startup mapping. */
typedef unsigned int U;typedef unsigned char B;
#define S __attribute__((stdcall))
#define D(p,o) (*(U*)((B*)(p)+(o)))
typedef U(S*Submit)(void*,void*,B*,void*,void*,U,void*,void*,U*,void*);
/* Exact XP828810/828330/828410 admits PSI10/20 and the single NVVDD
 * legacy rail map.39152AC3E..52AC9C selects split-current use for that
 * LEGACY HAL only if logic and SRAM domains both map. No inferred flag
 * is borrowed from a later object layout. Native typed BIOS read retains
 * address translation/bounds/error handling. */
typedef U(S*Table)(void*,U*);
typedef U(S*Read)(void*,void*,U,U,const char*);
typedef B(S*Domain)(void*,void*,U);
U S psi_legacy_startup593(void*gpu,const B*cmd,U*split){
 U controllers=D(cmd,24),address=0,version=0,status;
 if(controllers&~7u)return 0x1f;
 *split=0;
 if(!controllers)return 0;
 B*bios=(B*)D(gpu,0x1650),*volt=(B*)D(gpu,0x1658);
 if(!bios||!volt||!D(bios,0x1d4)||!D(bios,0xf0)||!D(volt,0x118))return 0x1f;
 status=((Table)D(bios,0x1d4))(bios,&address);if(status)return status;
 if(!address)return 0x56;
 char format[3]={'1','b',0};
 status=((Read)D(bios,0xf0))(bios,&version,address,0,format);if(status)return status;
 /* Table30 introduces explicit rail-HAL enumeration and is rejected by
  * the original XP parser. Its producer is not represented by this command.
  * Preserve a real unsupported error before publishing a partial config. */
 if(version!=0x10&&version!=0x20)return 0x40;
 U logic=((Domain)D(volt,0x118))(gpu,volt,1);
 U sram=((Domain)D(volt,0x118))(gpu,volt,2);
 *split=logic!=255&&sram!=255;return 0;
}
U S psi_translate593(Submit fn,void*gpu,void*pmu,B*cmd,void*reply,void*desc,U queue,void*cb,void*arg,U*seq,void*timer){
 if(!fn||!gpu||!pmu||!cmd||reply||desc||queue||arg||!seq||!timer||cmd[0]!=3||cmd[1]!=32||cmd[4]!=14||cmd[5]||cmd[7]||cmd[6]>3)return 0x1f;
 U split=0;
 if(!cmd[6]&&cb)return 0x1f;
 if(!cmd[6]){U status=psi_legacy_startup593(gpu,cmd,&split);if(status)return status;}
 B wire[16]={3,16,0,0,14,0,0,0};
 if(cmd[6]==0){if(cb)return 0x1f;D(wire,8)=D(cmd,16);D(wire,12)=D(cmd,20);}
 else if(cmd[6]==1){
  /* Actual XP8294F0 emits controller0/1/2 with200000/20/30.
   * Native3915BB2C8 omits that legacy field and sends controller+rail mask.
   * PSI10/20's native HAL map contains only NVVDD; mask1 is its ABI mapping,
   * not a board-derived assumption about an arbitrary number of rails. */
  U id=cmd[8],legacy=id==0?200000:id==1?20:30;
  if(!cb||id>2||D(cmd,12)!=legacy)return 0x1f;
  wire[6]=2;wire[8]=(B)id;wire[9]=1;
 }
 else {
  if(cb)return 0x1f;
  wire[6]=cmd[6]+1;
  if(cmd[6]==2){
   /* XP8296B0/829350 selector0/1 names the logic/SRAM crossover
    * current within NVVDD. Native3915BB1B0 ->5BA862 ->5BAA00
    * separates rail0 at byte8 from that current selector at byte9.
    * This path has no legacy input for another native PSI rail. */
   if(cmd[8]>1)return 0x1f;
   wire[8]=0;wire[9]=cmd[8];D(wire,12)=D(cmd,12);
  }else wire[8]=cmd[8];
 }
 U status=fn(gpu,pmu,wire,reply,desc,queue,cb,arg,seq,timer);
 if(status||cmd[6]||!D(cmd,24))return status;
 /* Native391 global -> supported rail init -> controller init order.
  * Legacy PSI has only rail0; a controller mask of zero initializes no rail.
  * Use the existing SRAM current only under the proven native split rule. */
 wire[6]=1;wire[8]=0;wire[9]=cmd[8];wire[10]=cmd[9];wire[11]=cmd[10];
 wire[12]=cmd[12];wire[13]=cmd[13];wire[14]=split?cmd[14]:0;wire[15]=split?cmd[15]:0;
 return fn(gpu,pmu,wire,reply,desc,queue,cb,arg,seq,timer);
}
