.intel_syntax noprefix
.code32
.section .text
.global sourceTable
sourceTable:
 call 1f
1: pop eax
 add eax, OFFSET FLAT:source_table-1b
 ret
.balign 4
source_table:
 /* GF100 */
 .long 192,0,225000,0
 /* GF108 */
 .long 192,1,225000,0
 /* GF106 */
 .long 192,3,225000,0
 /* GF104 */
 .long 192,4,225000,0
 /* GF110 */
 .long 192,8,225000,0
 /* GF114 */
 .long 192,14,225000,0
 /* GF116 */
 .long 192,15,225000,0
 /* GF119 */
 .long 208,9,225000,0
 /* GK104 */
 .long 224,4,297000,1
 /* GK106 */
 .long 224,6,297000,1
 /* GK107 */
 .long 224,7,297000,1
 /* GK110 */
 .long 240,0,297000,1
 /* GK110B */
 .long 240,1,297000,1
 /* GK208B */
 .long 256,6,297000,1
 /* GK208 */
 .long 256,8,297000,1
 /* GM107 */
 .long 272,7,297000,1
 /* GM200 */
 .long 288,0,594000,3
 /* GM204 */
 .long 288,4,594000,3
 /* GM206 */
 .long 288,6,594000,3
 /* GP102 */
 .long 304,2,594000,3
 /* GP104 */
 .long 304,4,594000,3
 /* GP106 */
 .long 304,6,594000,3
 /* GP107 */
 .long 304,7,594000,3
.section .note.GNU-stack,"",@progbits
