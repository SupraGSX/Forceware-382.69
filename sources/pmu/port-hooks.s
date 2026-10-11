.intel_syntax noprefix
.section .entry,"ax"
.global hook_read
hook_read:
lea edx,[esp+4]
call 1f
1: pop eax
.byte 0x2d
.long 1b-65536
push edx
push 0
push eax
call port_transfer
add esp,12
ret 24
.global hook_write
hook_write:
lea edx,[esp+4]
call 1f
1: pop eax
.byte 0x2d
.long 1b-65536
push edx
push 1
push eax
call port_transfer
add esp,12
ret 24
.global hook_old_read
hook_old_read:
lea edx,[esp+4]
call 1f
1: pop eax
.byte 0x2d
.long 1b-65536
push edx
push 2
push eax
call port_transfer
add esp,12
ret 24
.global hook_old_write
hook_old_write:
lea edx,[esp+4]
call 1f
1: pop eax
.byte 0x2d
.long 1b-65536
push edx
push 3
push eax
call port_transfer
add esp,12
ret 24
.section .tramp,"ax"
.org 0
orig_read:
push ecx
mov eax,[esp+12]
jmp 0x6f8e15
.org 32
orig_write:
sub esp,16
mov eax,[esp+24]
jmp 0x6f8f97
.org 64
orig_old_read:
mov ecx,[esp+20]
test ecx,ecx
jmp 0x5c7006
.org 96
orig_old_write:
push ecx
push ebx
mov ebx,[esp+28]
jmp 0x5c7616
.section .text
.global hook_inline_enter
hook_inline_enter:
pushfd
pushad
cld
call 1f
1: pop eax
.byte 0x2d
.long 1b-65536
push eax
call port_inline_enter
add esp,4
popad
popfd
push 0x10a1c0
jmp 0x5c7ea1
.global hook_inline_leave
hook_inline_leave:
call eax
pushfd
pushad
cld
call 1f
1: pop eax
.byte 0x2d
.long 1b-65536
push eax
call port_inline_leave
add esp,4
popad
popfd
mov ebx,[esp+0x10]
jmp 0x5c7fac
.section .note.GNU-stack,"",@progbits
