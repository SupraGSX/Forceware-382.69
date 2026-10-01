.intel_syntax noprefix
.code32
.text
.global _start
_start:
 cmp eax,10
 je accept
 cmp eax,20
 je accept
 cmp eax,30
 je accept
 mov [esp+0x64],ebx
accept:
 jmp 0x48289
