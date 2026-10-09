.intel_syntax noprefix
.code32
.section .text
.global gp107_fecs, gp107_gpccs, get_fecs_boot, get_gpccs_boot
.global fecs_boot_descriptor, gpccs_boot_descriptor, fecs_boot_payload, gpccs_boot_payload
# Preserve the October 8 GP107 constructors and all their existing overrides.
# Only GP107's two registration pointers are redirected to these wrappers.
# Match the intact 376.84 boot code to its existing GP107 application/signature.
# The staged 0x100-byte boot descriptor has the XP 0x4c-byte fields followed
# by zero padding. The donor reads argc/argv at 0x4c/0x50: both remain zero.
.macro delta reg
 call 991f
991: pop \reg
 sub \reg, OFFSET FLAT:991b
.endm
.macro ctor name, old, slot, getter, descriptor, payload
\name:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call \old
 push eax
 delta ebx
 lea eax,[ebx+\payload]
 mov [ebx+\descriptor+4],eax
 lea eax,[ebx+\getter]
 mov [esi+\slot],eax
 pop eax
 pop esi
 pop ebx
 ret 8
.endm
ctor gp107_fecs, original_gp107_fecs, 0x34, get_fecs_boot, fecs_boot_descriptor, fecs_boot_payload
ctor gp107_gpccs, original_gp107_gpccs, 0x30, get_gpccs_boot, gpccs_boot_descriptor, gpccs_boot_payload
get_fecs_boot:
 delta eax
 add eax, OFFSET FLAT:fecs_boot_descriptor
 ret 4
get_gpccs_boot:
 delta eax
 add eax, OFFSET FLAT:gpccs_boot_descriptor
 ret 4
.balign 16
fecs_boot_descriptor: .long 512,0,0
gpccs_boot_descriptor: .long 512,0,0
.balign 16
fecs_boot_payload: .incbin "fecs-boot376.bin"
gpccs_boot_payload: .incbin "gpccs-boot376.bin"
.section .note.GNU-stack,"",@progbits
