.intel_syntax noprefix
.code32
.section .text
.global register_gp107, gp107_fecs, gp107_gpccs, gp107_gr
.global gp107_attrib, gp107_bundle, gp107_gfxp, gp107_caps
.global family_table, fecs_descriptor, gpccs_descriptor, gr_descriptor
.global get_fecs, get_gpccs, get_gr
# Each address below is calculated from EIP or reached with rel32. No new PE
# relocations are required. Existing XP pointers are copied after PE relocation.
.macro delta reg
 call 991f
991: pop \reg
 sub \reg, OFFSET FLAT:991b
.endm
.macro address reg, symbol
 delta \reg
 add \reg, OFFSET FLAT:\symbol
.endm
.macro set_callback off, symbol
 lea eax,[ebx+\symbol]
 mov [esi+\off],eax
.endm

# Replaces only the final CALL to the GP106 registration wrapper. Its original
# status is preserved; GP107 registration is appended after GP106 succeeds.
register_gp107:
 call original_gp106_registration
 test eax,eax
 jnz 9f
 push ebx
 push esi
 push edi
 delta ebx
 lea esi,[ebx+original_gp106_table]
 lea edi,[ebx+family_table]
 mov ecx,82
 rep movsd
 lea esi,[ebx+family_table]
 # Later supported GP107 uses GP104 implementations for these differing slots.
 lea edx,[ebx+original_gp104_table]
 .irp off,0x00,0x20,0x28,0xc8,0xd4,0xdc,0xe4
 mov eax,[edx+\off]
 mov [esi+\off],eax
 .endr
 set_callback 0x48,gp107_fecs
 set_callback 0x64,gp107_gpccs
 set_callback 0x74,gp107_gr
 # Keep XP GP106's legacy-format class/engine tables: equivalent GP107 engine
 # counts/classes, excluding unrelated class additions in newer Windows RM.
 .irp pair,fecs,gpccs,gr
 lea eax,[ebx+\pair\()_payload]
 mov [ebx+\pair\()_descriptor+4],eax
 .endr
 push esi
 push 0x3b
 call register_family
 pop edi
 pop esi
 pop ebx
9: ret

gp107_fecs:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp104_fecs
 delta ebx
 set_callback 0x2c,get_fecs
 pop esi
 pop ebx
 ret 8

gp107_gpccs:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp104_gpccs
 delta ebx
 set_callback 0x28,get_gpccs
 pop esi
 pop ebx
 ret 8

gp107_gr:
 push ebx
 push esi
 mov esi,[esp+16]
 push esi
 push dword ptr [esp+16]
 call original_gp104_gr
 delta ebx
 set_callback 0x20,gp107_attrib
 set_callback 0x38,gp107_bundle
 set_callback 0x360,gp107_gfxp
 set_callback 0x3d8,gp107_caps
 set_callback 0x3e8,get_gr
 pop esi
 pop ebx
 ret 8

gp107_attrib:
 mov eax,[esp+12]
 test eax,eax
 jz 1f
 mov dword ptr [eax],0x540
1: mov eax,[esp+16]
 test eax,eax
 jz 2f
 mov dword ptr [eax],0x800
2: xor eax,eax
 ret 16

gp107_bundle:
 mov eax,[esp+12]
 test eax,eax
 jz 1f
 mov dword ptr [eax],0x30
1: mov eax,[esp+16]
 test eax,eax
 jz 2f
 mov dword ptr [eax],0x300
2: mov eax,[esp+20]
 test eax,eax
 jz 3f
 mov dword ptr [eax],0x300
3: xor eax,eax
 ret 20

# ABI from XP 6F8850, values from GP107 376.84 88B63C. The donor's
# offsets 148/63C/D8/DC/E0/E4/F4/F8 must NOT be used with XP objects.
gp107_gfxp:
 mov eax,[esp+8]
 mov ecx,[eax+0x640]
 mov edx,[eax+0x158]
 push 0x17
 push ecx
 call edx
 mov dword ptr [eax+0xec],0xe94
 mov dword ptr [eax+0xf0],0xe94
 mov dword ptr [eax+0xf4],0x4a0
 mov dword ptr [eax+0xf8],0x100
 mov dword ptr [eax+0x108],0x200
 mov dword ptr [eax+0x10c],0x200
 xor eax,eax
 ret 8

# Retain XP's original feature initialization; the 376.84 GP107 delta omits
# GP104 flag +626. Matching the neighboring XP flag ordering maps it to +62D.
# This is an inferred field mapping and remains a hardware-validation target.
gp107_caps:
 push esi
 mov esi,[esp+12]
 push esi
 push dword ptr [esp+12]
 call original_gp104_caps
 mov byte ptr [esi+0x62d],0
 pop esi
 ret 8

get_fecs:
 address eax,fecs_descriptor
 ret 4
get_gpccs:
 address eax,gpccs_descriptor
 ret 4
get_gr:
 address eax,gr_descriptor
 ret 4

.balign 16
family_table: .zero 0x148
fecs_descriptor: .long 192,0,0
gpccs_descriptor: .long 192,0,0
gr_descriptor: .long gr_payload_end-gr_payload,0,0
.balign 16
fecs_payload: .incbin "fecs-signature.bin"
gpccs_payload: .incbin "gpccs-signature.bin"
gr_payload: .incbin "gr-bundle.bin"
gr_payload_end:
.section .note.GNU-stack,"",@progbits
