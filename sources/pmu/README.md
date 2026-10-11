# PMU synchronization

`receive-owner.s` protects queue receive transactions without spinning or holding
ownership over upper callbacks. `port-lock.c` and `port-hooks.s` protect complete
shared DMEM transfers, using a separate native x86 IRQL-26 lock and bounded
64-byte stack staging. The native driver lock used for individual MMIO accesses
is distinct. `hooks.json` records the exact guarded hook bytes and code ranges.

Compile the assembly with GNU binutils and the C source with GCC i686,
freestanding, `-Os`, no PIC/PIE, SSE/MMX or stack protector; use a 4-byte stack
boundary. The supplied linker scripts fix the verified image locations.
`verify_pmu.py` compiles and compares these sources against the rebuilt miniport.
No diagnostic recorder, malformed-header discard or response-timeout shortcut
is included. Physical interrupt latency and reset lifecycle remain validation
items; bounded bytes do not guarantee a wall-clock duration in a VM.
