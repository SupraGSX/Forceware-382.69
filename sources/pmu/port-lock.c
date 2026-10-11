/* Exact-image x86 XP PMU transfer serialization. No queue discard or timeout.
 * A separate nonpaged lock uses the image's existing IRQL-26 primitive. Device
 * IRQs cannot preempt its local owner; clock/profile/IPI remain serviceable.
 * Lock order is receive owner -> port lock -> native per-MMIO bookkeeping.
 * Never hold this lock around upper PMU callbacks or response waits.
 */
typedef unsigned U; typedef unsigned long long Q;
#define ST __attribute__((stdcall))
#define V(p) (*(volatile U*)(p))
#define STATE 0xdb7f00u
#define RD 0xdb7100u
#define WR 0xdb7120u
#define OLD_RD 0xdb7140u
#define OLD_WR 0xdb7160u
#define CHUNK 64u
struct State {char magic[8];U lock,acquires,releases,contended,errors,max_chunk,inline_irql,inline_acquires;};
typedef U (ST *Transfer)(U,U,U,void*,U,U);
static void inc(volatile U*p){__asm__ volatile("lock incl %0":"+m"(*p)::"memory","cc");}
static struct State *st(U base){return (struct State*)(base+STATE);}
U port_enter(U base){struct State*s=st(base);if(s->lock)inc(&s->contended);Q old=((Q(ST*)(U))(base+0x4798b0))((U)&s->lock);inc(&s->acquires);return (U)old;}
void port_leave(U base,U old){struct State*s=st(base);inc(&s->releases);((void(ST*)(U,U,U))(base+0x4798f0))((U)&s->lock,old,0);}
U port_transfer(U base,U kind,U*a){
 U off=a[2],n=a[4],buf=a[3],r,old; unsigned char stage[CHUNK];
 Transfer native=(Transfer)(base+(kind==0?RD:kind==1?WR:kind==2?OLD_RD:OLD_WR));
 /* Preserve native failure paths before any partial transfer. Legacy functions
    have no secure boundary; modern functions reject wrap and boundary crossing. */
 if(!n||(off&3))return native(a[0],a[1],off,(void*)buf,n,a[5]);
 if(kind<2){
  if(off+n<off)return native(a[0],a[1],off,(void*)buf,n,a[5]);
  U falcon=V(V(a[1]+0x188)+0x78);
  U boundary=((U(ST*)(U,U))V(falcon+0x140))(a[0],falcon);
  if(off<boundary&&off+n>boundary)return native(a[0],a[1],off,(void*)buf,n,a[5]);
 }
 /* Each chunk reprograms its own selector and includes all data/status/readback
    operations. Full words split only on 4-byte boundaries; final partial bytes
    retain native behavior. Whole input was validated above. */
 while(n){U count=n>CHUNK?CHUNK:n;
  /* Access caller memory at its original IRQL. Seed read staging too so native
     partial-output-on-error semantics survive an early security failure. */
  for(U j=0;j<count;j++)stage[j]=((unsigned char*)buf)[j];
  old=port_enter(base);
  if(st(base)->max_chunk<count)st(base)->max_chunk=count;
  r=native(a[0],a[1],off,stage,count,a[5]);
  if(r)inc(&st(base)->errors);
  port_leave(base,old);
  if(!(kind&1))for(U j=0;j<count;j++)((unsigned char*)buf)[j]=stage[j];
  if(r)return r;
  off+=count;buf+=count;n-=count;
 }
 return 0;
}
void port_inline_enter(U base){struct State*s=st(base);U old=port_enter(base);s->inline_irql=old;inc(&s->inline_acquires);if(s->max_chunk<40)s->max_chunk=40;}
void port_inline_leave(U base){port_leave(base,st(base)->inline_irql);}
