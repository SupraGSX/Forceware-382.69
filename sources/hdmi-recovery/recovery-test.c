#include "scdc-recovery.c"
static struct State state;
struct State *state_address(void) {return &state;}
static U calls,delays,failures;
void __attribute__((stdcall)) delay_native(U d) {if(d==2)delays++;}
static U __attribute__((stdcall)) writer(U gpu,U i2c,U bus,U address,U reg,U value) {calls++;return calls<=failures?0x14:0;}
static U i2c[160],connector[224];
#define CHECK(x,n) if(!(x))return n
static U test(void) {
 U c=(U)connector,io=(U)i2c;i2c[0x264/4]=(U)writer;
 failures=5;CHECK(setup_write(1,c,io,3)==0x14&&calls==1&&delays==0,1);
 calls=delays=0;CHECK(transaction(1,c,0xd8434401)==1,2);
 CHECK(setup_write(1,c,io,3)==0x14&&calls==3&&delays==2,3);
 CHECK(transaction(1,c,0xd8434402)==2,4);
 calls=delays=0;failures=2;CHECK(transaction(1,c,0xd8434401)==1,5);
 CHECK(setup_write(1,c,io,3)==0&&calls==3&&delays==2,6);
 failures=100;CHECK(setup_write(1,c,io,3)==0x14&&calls==4&&delays==2,7);
 CHECK(transaction(1,c,0xd8434402)==1,8);
 CHECK(transaction(1,c,0xd8434401)==1,9);CHECK(transaction(2,c,0xd8434401)==1,10);
 calls=0;failures=0;setup_write(1,c,io,3);CHECK(transaction(2,c,0xd8434402)==2,11);CHECK(transaction(1,c,0xd8434402)==1,12);
 CHECK(transaction(1,c,0xd8434401)==1,13);calls=0;failures=100;setup_write(1,c,io,0);CHECK(calls==1&&transaction(1,c,0xd8434402)==2,14);
 for(U n=0;n<32;n++)CHECK(transaction(n+1,c,0xd8434401)==1,15);
 CHECK(transaction(33,c,0xd8434401)==2,16);
 for(U n=0;n<32;n++)CHECK(transaction(n+1,c,0xd8434402)==2,17);
 CHECK(transaction(33,c,0xd8434401)==1,18);
 state.lock=1;CHECK(transaction(33,c,0xd8434402)==2,19);state.lock=0;
 CHECK(transaction(33,c,0xd8434402)==2,20);
 return 0;
}
void _start(void) {U code=test();__asm__ volatile("int $0x80"::"a"(1),"b"(code));__builtin_unreachable();}
