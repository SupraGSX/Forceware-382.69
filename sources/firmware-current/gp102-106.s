.intel_syntax noprefix
.code32
.section .text
.macro delta reg
 call 991f
991: pop \reg
 sub \reg, OFFSET FLAT:991b
.endm
.global gp102_fecs
gp102_fecs:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp102_fecs
 push eax
 delta ebx
 lea eax,[ebx+gp102_get_fecs_signature]
 mov [esi+0x28],eax
 lea eax,[ebx+gp102_get_fecs_boot]
 mov [esi+0x34],eax
 lea eax,[ebx+gp102_get_fecs_header]
 mov [esi+0x38],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp102_gpccs
gp102_gpccs:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp102_gpccs
 push eax
 delta ebx
 lea eax,[ebx+gp102_get_gpccs_signature]
 mov [esi+0x24],eax
 lea eax,[ebx+gp102_get_gpccs_boot]
 mov [esi+0x30],eax
 lea eax,[ebx+gp102_get_gpccs_header]
 mov [esi+0x34],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp102_gr
gp102_gr:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp102_gr
 push eax
 delta ebx
 lea eax,[ebx+gp102_get_gr_bundle]
 mov [esi+0x3e4],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp102_get_fecs_signature
gp102_get_fecs_signature:
 delta eax
 lea edx,[eax+gp102_fecs_signature_payload]
 mov [eax+gp102_fecs_signature_descriptor+4],edx
 add eax, OFFSET FLAT:gp102_fecs_signature_descriptor
 ret 4
.global gp102_get_gpccs_signature
gp102_get_gpccs_signature:
 delta eax
 lea edx,[eax+gp102_gpccs_signature_payload]
 mov [eax+gp102_gpccs_signature_descriptor+4],edx
 add eax, OFFSET FLAT:gp102_gpccs_signature_descriptor
 ret 4
.global gp102_get_gr_bundle
gp102_get_gr_bundle:
 delta eax
 lea edx,[eax+gp102_gr_bundle_payload]
 mov [eax+gp102_gr_bundle_descriptor+4],edx
 add eax, OFFSET FLAT:gp102_gr_bundle_descriptor
 ret 4
.global gp102_get_fecs_boot
gp102_get_fecs_boot:
 delta eax
 lea edx,[eax+gp102_fecs_boot_payload]
 mov [eax+gp102_fecs_boot_descriptor+4],edx
 add eax, OFFSET FLAT:gp102_fecs_boot_descriptor
 ret 4
.global gp102_get_fecs_header
gp102_get_fecs_header:
 delta eax
 lea edx,[eax+gp102_fecs_header_payload]
 mov [eax+gp102_fecs_header_descriptor+4],edx
 add eax, OFFSET FLAT:gp102_fecs_header_descriptor
 ret 4
.global gp102_get_gpccs_boot
gp102_get_gpccs_boot:
 delta eax
 lea edx,[eax+gp102_gpccs_boot_payload]
 mov [eax+gp102_gpccs_boot_descriptor+4],edx
 add eax, OFFSET FLAT:gp102_gpccs_boot_descriptor
 ret 4
.global gp102_get_gpccs_header
gp102_get_gpccs_header:
 delta eax
 lea edx,[eax+gp102_gpccs_header_payload]
 mov [eax+gp102_gpccs_header_descriptor+4],edx
 add eax, OFFSET FLAT:gp102_gpccs_header_descriptor
 ret 4
.global gp104_fecs
gp104_fecs:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp104_fecs
 push eax
 delta ebx
 lea eax,[ebx+gp104_get_fecs_signature]
 mov [esi+0x2c],eax
 lea eax,[ebx+gp104_get_fecs_boot]
 mov [esi+0x34],eax
 lea eax,[ebx+gp104_get_fecs_header]
 mov [esi+0x38],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp104_gpccs
gp104_gpccs:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp104_gpccs
 push eax
 delta ebx
 lea eax,[ebx+gp104_get_gpccs_signature]
 mov [esi+0x28],eax
 lea eax,[ebx+gp104_get_gpccs_boot]
 mov [esi+0x30],eax
 lea eax,[ebx+gp104_get_gpccs_header]
 mov [esi+0x34],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp104_gr
gp104_gr:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp104_gr
 push eax
 delta ebx
 lea eax,[ebx+gp104_get_gr_bundle]
 mov [esi+0x3e8],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp104_get_fecs_signature
gp104_get_fecs_signature:
 delta eax
 lea edx,[eax+gp104_fecs_signature_payload]
 mov [eax+gp104_fecs_signature_descriptor+4],edx
 add eax, OFFSET FLAT:gp104_fecs_signature_descriptor
 ret 4
.global gp104_get_gpccs_signature
gp104_get_gpccs_signature:
 delta eax
 lea edx,[eax+gp104_gpccs_signature_payload]
 mov [eax+gp104_gpccs_signature_descriptor+4],edx
 add eax, OFFSET FLAT:gp104_gpccs_signature_descriptor
 ret 4
.global gp104_get_gr_bundle
gp104_get_gr_bundle:
 delta eax
 lea edx,[eax+gp104_gr_bundle_payload]
 mov [eax+gp104_gr_bundle_descriptor+4],edx
 add eax, OFFSET FLAT:gp104_gr_bundle_descriptor
 ret 4
.global gp104_get_fecs_boot
gp104_get_fecs_boot:
 delta eax
 lea edx,[eax+gp104_fecs_boot_payload]
 mov [eax+gp104_fecs_boot_descriptor+4],edx
 add eax, OFFSET FLAT:gp104_fecs_boot_descriptor
 ret 4
.global gp104_get_fecs_header
gp104_get_fecs_header:
 delta eax
 lea edx,[eax+gp104_fecs_header_payload]
 mov [eax+gp104_fecs_header_descriptor+4],edx
 add eax, OFFSET FLAT:gp104_fecs_header_descriptor
 ret 4
.global gp104_get_gpccs_boot
gp104_get_gpccs_boot:
 delta eax
 lea edx,[eax+gp104_gpccs_boot_payload]
 mov [eax+gp104_gpccs_boot_descriptor+4],edx
 add eax, OFFSET FLAT:gp104_gpccs_boot_descriptor
 ret 4
.global gp104_get_gpccs_header
gp104_get_gpccs_header:
 delta eax
 lea edx,[eax+gp104_gpccs_header_payload]
 mov [eax+gp104_gpccs_header_descriptor+4],edx
 add eax, OFFSET FLAT:gp104_gpccs_header_descriptor
 ret 4
.global gp106_fecs
gp106_fecs:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp106_fecs
 push eax
 delta ebx
 lea eax,[ebx+gp106_get_fecs_signature]
 mov [esi+0x28],eax
 lea eax,[ebx+gp106_get_fecs_boot]
 mov [esi+0x34],eax
 lea eax,[ebx+gp106_get_fecs_header]
 mov [esi+0x38],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp106_gpccs
gp106_gpccs:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp106_gpccs
 push eax
 delta ebx
 lea eax,[ebx+gp106_get_gpccs_signature]
 mov [esi+0x24],eax
 lea eax,[ebx+gp106_get_gpccs_boot]
 mov [esi+0x30],eax
 lea eax,[ebx+gp106_get_gpccs_header]
 mov [esi+0x34],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp106_gr
gp106_gr:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp106_gr
 push eax
 delta ebx
 lea eax,[ebx+gp106_get_gr_bundle]
 mov [esi+0x3e4],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.global gp106_get_fecs_signature
gp106_get_fecs_signature:
 delta eax
 lea edx,[eax+gp106_fecs_signature_payload]
 mov [eax+gp106_fecs_signature_descriptor+4],edx
 add eax, OFFSET FLAT:gp106_fecs_signature_descriptor
 ret 4
.global gp106_get_gpccs_signature
gp106_get_gpccs_signature:
 delta eax
 lea edx,[eax+gp106_gpccs_signature_payload]
 mov [eax+gp106_gpccs_signature_descriptor+4],edx
 add eax, OFFSET FLAT:gp106_gpccs_signature_descriptor
 ret 4
.global gp106_get_gr_bundle
gp106_get_gr_bundle:
 delta eax
 lea edx,[eax+gp106_gr_bundle_payload]
 mov [eax+gp106_gr_bundle_descriptor+4],edx
 add eax, OFFSET FLAT:gp106_gr_bundle_descriptor
 ret 4
.global gp106_get_fecs_boot
gp106_get_fecs_boot:
 delta eax
 lea edx,[eax+gp106_fecs_boot_payload]
 mov [eax+gp106_fecs_boot_descriptor+4],edx
 add eax, OFFSET FLAT:gp106_fecs_boot_descriptor
 ret 4
.global gp106_get_fecs_header
gp106_get_fecs_header:
 delta eax
 lea edx,[eax+gp106_fecs_header_payload]
 mov [eax+gp106_fecs_header_descriptor+4],edx
 add eax, OFFSET FLAT:gp106_fecs_header_descriptor
 ret 4
.global gp106_get_gpccs_boot
gp106_get_gpccs_boot:
 delta eax
 lea edx,[eax+gp106_gpccs_boot_payload]
 mov [eax+gp106_gpccs_boot_descriptor+4],edx
 add eax, OFFSET FLAT:gp106_gpccs_boot_descriptor
 ret 4
.global gp106_get_gpccs_header
gp106_get_gpccs_header:
 delta eax
 lea edx,[eax+gp106_gpccs_header_payload]
 mov [eax+gp106_gpccs_header_descriptor+4],edx
 add eax, OFFSET FLAT:gp106_gpccs_header_descriptor
 ret 4
.balign 16
gp102_fecs_signature_descriptor: .long 192,0,0
gp102_fecs_signature_payload: .incbin "gp102-fecs-signature.bin"
.balign 16
gp102_gpccs_signature_descriptor: .long 192,0,0
gp102_gpccs_signature_payload: .incbin "gp102-gpccs-signature.bin"
.balign 16
gp102_gr_bundle_descriptor: .long 86626,0,0
gp102_gr_bundle_payload: .incbin "gp102-gr-bundle.bin"
.balign 16
gp102_fecs_boot_descriptor: .long 512,0,0
gp102_fecs_boot_payload: .incbin "gp102-fecs-boot.bin"
.balign 16
gp102_fecs_header_descriptor: .long 24,0,0
gp102_fecs_header_payload: .incbin "gp102-fecs-header.bin"
.balign 16
gp102_gpccs_boot_descriptor: .long 512,0,0
gp102_gpccs_boot_payload: .incbin "gp102-gpccs-boot.bin"
.balign 16
gp102_gpccs_header_descriptor: .long 24,0,0
gp102_gpccs_header_payload: .incbin "gp102-gpccs-header.bin"
.balign 16
gp104_fecs_signature_descriptor: .long 192,0,0
gp104_fecs_signature_payload: .incbin "gp104-fecs-signature.bin"
.balign 16
gp104_gpccs_signature_descriptor: .long 192,0,0
gp104_gpccs_signature_payload: .incbin "gp104-gpccs-signature.bin"
.balign 16
gp104_gr_bundle_descriptor: .long 90320,0,0
gp104_gr_bundle_payload: .incbin "gp104-gr-bundle.bin"
.balign 16
gp104_fecs_boot_descriptor: .long 512,0,0
gp104_fecs_boot_payload: .incbin "gp104-fecs-boot.bin"
.balign 16
gp104_fecs_header_descriptor: .long 24,0,0
gp104_fecs_header_payload: .incbin "gp104-fecs-header.bin"
.balign 16
gp104_gpccs_boot_descriptor: .long 512,0,0
gp104_gpccs_boot_payload: .incbin "gp104-gpccs-boot.bin"
.balign 16
gp104_gpccs_header_descriptor: .long 24,0,0
gp104_gpccs_header_payload: .incbin "gp104-gpccs-header.bin"
.balign 16
gp106_fecs_signature_descriptor: .long 192,0,0
gp106_fecs_signature_payload: .incbin "gp106-fecs-signature.bin"
.balign 16
gp106_gpccs_signature_descriptor: .long 192,0,0
gp106_gpccs_signature_payload: .incbin "gp106-gpccs-signature.bin"
.balign 16
gp106_gr_bundle_descriptor: .long 90288,0,0
gp106_gr_bundle_payload: .incbin "gp106-gr-bundle.bin"
.balign 16
gp106_fecs_boot_descriptor: .long 512,0,0
gp106_fecs_boot_payload: .incbin "gp106-fecs-boot.bin"
.balign 16
gp106_fecs_header_descriptor: .long 24,0,0
gp106_fecs_header_payload: .incbin "gp106-fecs-header.bin"
.balign 16
gp106_gpccs_boot_descriptor: .long 512,0,0
gp106_gpccs_boot_payload: .incbin "gp106-gpccs-boot.bin"
.balign 16
gp106_gpccs_header_descriptor: .long 24,0,0
gp106_gpccs_header_payload: .incbin "gp106-gpccs-header.bin"
.section .note.GNU-stack,"",@progbits
