SECTIONS { . = 0xD06B20; .text : { *(.hook) *(.text) } /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) } }
rmControl = 0x445D90;
resume = 0x4588A9;
