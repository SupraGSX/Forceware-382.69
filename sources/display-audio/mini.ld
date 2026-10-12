SECTIONS { . = STUB; .text : { *(.early) *(.refresh) *(.receiver) *(.text*) *(.rodata*) } /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) } }
rmControl = 0x445D90;
legacyQuery = 0x46DAF0;
nativeHdmi = 0x44B8D0;
early_resume = 0x4567AE;
refresh_resume = 0x4588A9;
receiver_resume = 0x79C581;
query_resume = 0x44B926;
allocatePool = 0x4646BC;
freePool = 0x4646B6;
findDisplay = 0x441BE0;
nativeSummary = 0x874150;
nativeRate = 0x441D40;
nativeMulDiv = 0x103E0;

dp_audio_presence_resume = 0x44C8FD;
