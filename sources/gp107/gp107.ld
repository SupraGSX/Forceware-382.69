SECTIONS { . = 0xd07c40; .text : { *(.text*) } /DISCARD/ : { *(.note*) *(.comment*) *(.eh_frame*) } }
original_gp106_registration = 0x4ee220;
original_gp106_table = 0xb7b410;
original_gp104_table = 0xb7b2c8;
register_family = 0x511780;
original_gp104_fecs = 0x4f0600;
original_gp104_gpccs = 0x4f0770;
original_gp104_gr = 0x4f1270;
original_gp104_caps = 0x4e1430;
gp107_fecs_boot = 0xd6a4e0; gp107_gpccs_boot = 0xd6a518; gp107_register_finish = 0xd6a9a0;
