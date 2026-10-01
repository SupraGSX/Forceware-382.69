.intel_syntax noprefix
.code32
.text
.global _start
_start:
 mov eax,[esp+8]
 test eax,eax
 jz invalid
 mov byte ptr [eax],1
 .byte 0x33,0xc0  # xor eax,eax; retain the originally emitted encoding
 ret
invalid:
 mov eax,1
 ret
