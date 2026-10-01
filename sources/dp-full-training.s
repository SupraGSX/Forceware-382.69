.intel_syntax noprefix
.code32
.text
.global _start
_start:
 cmp ecx,20
 je full
 cmp ecx,30
 je full
 and dword ptr [esp+0x14],0
full:
 jmp 0x44dffc
