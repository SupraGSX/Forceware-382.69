SECTIONS { . = STUB; .text : { *(.text*) *(.rodata*) } /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) } }
deviceControl = 0x24DD24;
validate_resume = 0x4B7DA;
failure_resume = 0x4B800;
