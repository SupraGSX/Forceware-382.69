/* XP368.81 display: HDMI must stay single-link TMDS. Original DVI rule
 * remains at 165 MHz. Both GPU/output HDMI bit and sink HDMI bit required.
 * Windows 47990 query ABI confirmed at its stock mode-setting callers. */
.intel_syntax noprefix
.code32
.section .text
.global _start
_start:
 pushad
 /* Original [esp+1c] is the physical output mask, never an HDMI flag. */
 mov eax,[esp+0x3c]
 mov ecx,esi
 call hdmi_query
 and eax,3
 cmp eax,3
 popad
 je single
 cmp dword ptr [edx+0x18],165000
 jmp stock_compare
single:
 jmp stock_single
.section .note.GNU-stack,"",@progbits
