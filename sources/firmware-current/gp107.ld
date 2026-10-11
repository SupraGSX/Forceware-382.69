SECTIONS { . = 0xd6abc0; .text : { *(.text*) } /DISCARD/ : { *(.note*) *(.comment*) *(.eh_frame*) } }
original_gp107_fecs_boot = 0xd6a4e0;
