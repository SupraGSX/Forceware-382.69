.intel_syntax noprefix
.code32
.text
.global native_cap
native_cap:
.incbin "original.bin",0,576
jmp cap_compare
nop
nop
cap_compare_return:
.incbin "original.bin",583,87
jmp cap_divide
.fill 21,1,0x90
cap_divide_return:
.incbin "original.bin",696,18
cmp ecx,DWORD PTR [esp+0x54]
nop
nop
.incbin "original.bin",720,84
ret 28
.incbin "original.bin",807,10
ret 28
.incbin "original.bin",820,0
cap_compare:
push ecx
mov ecx,[esp+0x58]
cmp DWORD PTR [eax+0x2a],ecx
pop ecx
jmp cap_compare_return
cap_divide:
mov eax,[edx+esi+0x30]
xor edx,edx
div DWORD PTR [esp+0x54]
mov ebx,eax
mov eax,ecx
xor edx,edx
div DWORD PTR [esp+0x54]
cmp ebx,eax
jmp cap_divide_return
