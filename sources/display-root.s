.intel_syntax noprefix
.code32
.text
.global _start
_start:
 test ecx,0x80000
 jz fallback
 .byte 0x33,0xc9  # xor ecx,ecx; retain the originally emitted encoding
 mov [esp+8],ecx
 mov [esp+12],ecx
 mov [esp+16],ecx
 mov [esp+20],ecx
 lea ecx,[esp+8]
 push ecx
 push 0x9870
 jmp 0xb4e6c
fallback:
 .byte 0x8b,0xd1  # mov edx,ecx; replay the original displaced bytes
 shr edx,0x15
 jmp 0xb4e23
