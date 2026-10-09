.section .text
.global gp107_dp_default
/* XP 368.81 DisplayPortCfgPolicy default, hook 448906 -> 448911.
 * ESI is the initialized display adapter. Read-only hardware trace verifies
 * +B54=architecture 130 and +B58=implementation 7 on the physical GTX 1050 Ti.
 * This is a conservative GP107 workaround, not a repair of HBR3 signaling.
 * Keep actual link training, receiver checks and the existing registry override.
 * All other chips retain the October 8 preference. No EDID/DPCD edits.
 */
gp107_dp_default:
 pushfl
 pushl %eax
 movl $0x65432178,%eax
 cmpl $0x130,0xb54(%esi)
 jne 1f
 cmpl $7,0xb58(%esi)
 jne 1f
 movl $0x06543217,%eax
1:
 movl %eax,0x270(%esp) /* Original stack slot 268, plus our two pushes. */
 popl %eax
 popfl
 jmp original_dp_default_continue
.section .note.GNU-stack,"",@progbits
