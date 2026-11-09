typedef unsigned int U;
#define S __attribute__((stdcall))
#define D(p,o) (*(U*)((unsigned char*)(p)+(o)))
struct Slot { U owner,busy,gpu,pmu,object,cpu,mapped,api[8]; };
typedef U(S *Detach)(void*,void*,U);
typedef U(S *Cleanup)(struct Slot*,void*,void*);
/* Late first-start GPU-load failure only. All addresses and objects are
 * supplied by the PIC caller; no later-driver structures are transplanted.
 * Acknowledged native detach must precede existing lease-aware release.
 * Failure retains backing; original initialization status is never replaced. */
U S cleanup844(void*gpu,U original,U flags,struct Slot*slots,U provider,
               U detach,U cleanup) {
 U die,p,pmu,i,r;struct Slot*s=0;
 if(!original||flags||!gpu)return 0;
 die=D(gpu,0x710);
 if((die!=7&&die!=8)||D(gpu,0x714)!=0x130||*((unsigned char*)gpu+0x4ce))return 0;
 p=D(gpu,0x16e0);if(!p||D(p,0x1bc)!=provider)return 0;
 pmu=D(gpu,0x1674);if(!pmu)return 0;
 for(i=0;i<16;i++)if(slots[i].owner==pmu){s=slots+i;break;}
 if(!s||s->gpu!=(U)gpu||s->pmu!=pmu||!s->object||!s->mapped)return 0;
 if(D(pmu,0x1e0)!=detach||D(pmu,0x628)!=3)return 0;
 r=((Detach)detach)(gpu,(void*)pmu,1);if(r)return r;
 if(D(pmu,0x628)!=0)return 0x1f;
 return ((Cleanup)cleanup)(slots,gpu,(void*)pmu);
}
