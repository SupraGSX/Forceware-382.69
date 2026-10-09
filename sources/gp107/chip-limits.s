.intel_syntax noprefix
.code32
.section .text
.global gp107_register_finish, gp107_gpu, gp107_chip_limit
# Scoped replacement of the existing GP107-only registration call.
# Preserve GP106's XP class/engine getters; replace only the GPU limit query.
gp107_register_finish:
 push eax
 push ecx
 call 1f
1: pop eax
 sub eax, OFFSET FLAT:1b
 add eax, OFFSET FLAT:gp107_gpu
 mov ecx,[esp+16]
 mov [ecx+0x6c],eax
 pop ecx
 pop eax
 jmp original_register_family

gp107_gpu:
 push esi
 mov esi,[esp+12]
 push esi
 push dword ptr [esp+12]
 call original_gp106_gpu
 push eax
 call 2f
2: pop eax
 sub eax, OFFSET FLAT:2b
 add eax, OFFSET FLAT:gp107_chip_limit
 mov [esi+0xa4],eax
 pop eax
 pop esi
 ret 8

# GP107 architectural limits, supported 376.84 query88B25C.
# Selector ABI matches XP6DE840, not the donor's object offsets.
# 19 is max PPC/GPC (1); 14 and1B are3 TPCs. Actual fuse counts
# and masks are still discovered by original XP register readers.
gp107_chip_limit:
 mov eax,[esp+8]
 sub eax,0x11
 cmp eax,0xb
 ja zero
 call 3f
3: pop ecx
 sub ecx, OFFSET FLAT:3b
 movzx eax,byte ptr [ecx+eax+limits]
 ret 8
zero:
 xor eax,eax
 ret 8
limits: .byte 2,2,4,3,1,4,0,2,1,0,3,2
.section .note.GNU-stack,"",@progbits
