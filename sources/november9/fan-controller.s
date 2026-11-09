.intel_syntax noprefix
.section .text
.global controller_index639
controller_index639:
 # Native EAX is this row+2; ESI retains period, EBX retains control.
 # Move the already serialized XP cooler index from row1 into391 row2.
 push edx
 mov dl,byte ptr [eax-1]
 mov byte ptr [eax-1],0
 mov byte ptr [eax],dl
 mov byte ptr [eax+1],0xff
 pop edx
 jmp 0x10529e0
.section .note.GNU-stack,"",@progbits
