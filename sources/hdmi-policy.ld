SECTIONS { . = 0xD06D60; .text : { *(.early) *(.refresh) *(.receiver) *(.text) } /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) } }
rmControl = 0x445D90;
legacyQuery = 0x46DAF0;
nativeHdmi = 0x44B8D0;
early_resume = 0x4567AE;
refresh_resume = 0x4588A9;
receiver_resume = 0x79C581;
