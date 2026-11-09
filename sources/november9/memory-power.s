.intel_syntax noprefix
.section .text
.global gp108_ms_rppg_off790
gp108_ms_rppg_off790:
 # Native391 captured PMU RPPG_CTRL_MS is disabled. Keep all other bits.
 # Displaced MOV remains before original OR/CMP; those instructions replace flags.
 mov edi, DWORD PTR [ebx+0x180]
 and dh, 0xfe
 jmp 0x1058d06
