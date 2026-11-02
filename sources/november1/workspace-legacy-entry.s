.intel_syntax noprefix
.code32
.section .text
.global hook585
hook585:
 push edi
 push ecx
 call 1f
1: pop eax
 sub eax,OFFSET FLAT:1b
 lea eax,[eax+15782819]
 push eax
 call allocate585
 mov ebx,eax
 test ebx,ebx
 jmp 0x73d68e
.section .note.GNU-stack,"",@progbits
