.intel_syntax noprefix
.code32
.global _start
_start:
 jmp 0xd69100
.fill 55-(.-_start),1,0x90
