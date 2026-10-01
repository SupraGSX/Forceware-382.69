.intel_syntax noprefix
.code32
.global _start
_start:
 cmp al,8
 jbe train_keep
 mov al,8
train_keep:
 movzx eax,al
 lea ecx,[eax+eax*2]
 jmp 0x443d4f
.balign 32,0
recalc:
 cmp al,8
 jbe recalc_keep
 mov al,8
recalc_keep:
 movzx eax,al
 lea ecx,[eax+eax*2]
 jmp 0x457ef4
