/* Shared391 PSI voltage-rail control translator. The old helper name
 * adaptive-pg was inaccurate. Exact XP8296B0 and3915BB1B0 producers
 * establish separate rail/current selectors. Existing startup defaults
 * are retained; optional second-current enable and extra rails remain
 * separately unqualified. No firmware/status/readiness change. */
typedef unsigned int U;typedef unsigned char B;
#define S __attribute__((stdcall))
#define D(p,o) (*(U*)((B*)(p)+(o)))
typedef U(S*Submit)(void*,void*,B*,void*,void*,U,void*,void*,U*,void*);
U S psi_translate592(Submit fn,void*gpu,void*pmu,B*cmd,void*reply,void*desc,U queue,void*cb,void*arg,U*seq,void*timer){
 if(!fn||!gpu||!pmu||!cmd||reply||desc||queue||arg||!seq||!timer||cmd[0]!=3||cmd[1]!=32||cmd[4]!=14||cmd[5]||cmd[7]||cmd[6]>3)return 0x1f;
 B wire[16]={3,16,0,0,14,0,0,0};
 if(cmd[6]==0){if(cb)return 0x1f;D(wire,8)=D(cmd,16);D(wire,12)=D(cmd,20);}
 else if(cmd[6]==1){if(!cb||D(cmd,12)!=20)return 0x1f;wire[6]=2;wire[8]=cmd[8];wire[9]=1;}
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
 if(status||cmd[6])return status;
 /* Supported3915BB2C8 ->5BA966 sends this before stats allocation.
  * Existing XP PSI settings supply GPIO/flavor/crossover current; native
  * rail0 and omitted optional SRAM current retain observed P620 defaults. */
 wire[6]=1;wire[8]=0;wire[9]=cmd[8];wire[10]=cmd[9];wire[11]=cmd[10];
 wire[12]=cmd[12];wire[13]=cmd[13];wire[14]=wire[15]=0;
 return fn(gpu,pmu,wire,reply,desc,queue,cb,arg,seq,timer);
}
