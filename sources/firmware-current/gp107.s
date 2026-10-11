.intel_syntax noprefix
.code32
.section .text
.global gp107_fecs390, get_gr390
.macro delta reg
 call 991f
991: pop \reg
 sub \reg, OFFSET FLAT:991b
.endm
gp107_fecs390:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp107_fecs_boot
 push eax
 delta ebx
 lea eax,[ebx+get_header390]
 mov [esi+0x38],eax
 pop eax
 pop esi
 pop ebx
 ret 8
get_header390:
 delta eax
 lea edx,[eax+header_payload]
 mov [eax+header_descriptor+4],edx
 add eax, OFFSET FLAT:header_descriptor
 ret 4
get_gr390:
 delta eax
 lea edx,[eax+gr_payload]
 mov [eax+gr_descriptor+4],edx
 add eax, OFFSET FLAT:gr_descriptor
 ret 4
.balign 16
header_descriptor: .long 24,0,0
gr_descriptor: .long gr_end-gr_payload,0,0
header_payload: .incbin "fecs-header.bin"
.balign 16
gr_payload: .incbin "gr-bundle.bin"
gr_end:
.section .note.GNU-stack,"",@progbits
