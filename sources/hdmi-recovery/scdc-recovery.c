/* XP 368.81 paired-driver mode transaction. No Windows-object padding is used.
 * A successful setup write is latched only for this GPU/connector transaction.
 * Subsequent diagnostic reads are never a reason to tear down a working link.
 */
typedef unsigned int U;
typedef unsigned char B;
#define W(p,o) (*(U*)((B*)(p)+(o)))
#ifndef FAULT
#define FAULT 0
#endif
struct Slot { U gpu,connector,generation,active,seen,ok,attempts,last; };
struct State { volatile U lock; U serial; struct Slot slots[32]; };
extern struct State *state_address(void);
extern void __attribute__((stdcall)) delay_native(U);
typedef U (__attribute__((stdcall)) *Write)(U,U,U,U,U,U);
static U lock(struct State *s) {return __sync_bool_compare_and_swap(&s->lock,0,1);}
static void unlock(struct State *s) {__sync_lock_release(&s->lock);}
/* Private commands are intercepted before all legacy capability mutations. */
U transaction(U gpu,U connector,U command) {
 struct State*s=state_address();if(!lock(s))return 2;
 struct Slot *p=0,*free=0;
 for(U i=0;i<32;i++) {struct Slot*q=s->slots+i;if(!q->active&&!free)free=q;if(q->active&&q->gpu==gpu&&q->connector==connector)p=q;}
 U r=2;
 if(command==0xd8434401U) {
  if(!p)p=free;
  if(p) {*p=(struct Slot){gpu,connector,++s->serial,1,0,0,0,0};r=1;}
 } else if(command==0xd8434402U) {
  if(p) {r=p->seen&&p->ok?1:2;p->active=0;}
 }
 unlock(s);return r;
}
U setup_write(U gpu,U connector,U i2c,U value) {
 struct State*s=state_address();U generation=0,already=0,index=32;
 if((value&3)==3 && lock(s)) {
  for(U i=0;i<32;i++) {struct Slot*p=s->slots+i;if(p->active&&p->gpu==gpu&&p->connector==connector){index=i;generation=p->generation;already=p->ok;break;}}
  unlock(s);
 }
 Write write=(Write)W(i2c,0x264);U bus=W(connector,0x360),status=0,attempts=0;
 U limit=index<32&&!already?3:1;
 do {
  /* Fault injection exists only in explicitly named diagnostic binaries. */
  if(index<32&&!already && (FAULT==1 || (FAULT==2&&attempts<2)))status=0x14;
  else status=write(gpu,i2c,bus,0xa8,0x20,value);
  attempts++;
  if(!status||attempts==limit)break;
  delay_native(2);
 }while(1);
 if(index<32 && lock(s)) {
  struct Slot*p=s->slots+index;
  if(p->active&&p->generation==generation&&p->gpu==gpu&&p->connector==connector) {p->seen=1;p->ok|=!status;p->attempts+=attempts;p->last=status;}
  unlock(s);
 }
 return status;
}
