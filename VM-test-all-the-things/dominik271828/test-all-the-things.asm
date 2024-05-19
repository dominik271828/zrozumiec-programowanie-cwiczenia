%include "vm.inc" ; This program will ask the user for input, then wait the specified number of seconds (0 - 9) and then write "UP!" to stdout
; Set necessary registers
vset r1, 1
vset r2, 1000
vset r3, 48 ; sub 48 in order to get the numerical value of the ascii
vset r6, 0
vset r5, interrupt_handler

; Reset the alarm - not necessary 
; voutb 0x71, r6
; voutb 0x71, r6

vinb 0x20, r4 ; Read the number of miliseconds
vsub r4, r3 ; Get the numerical value of the number
vmul r4, r2 ; Turn miliseconds into seconds

; Get the upper and lower 8-bit parts of user input
vset r8, 8
vset r10, 0xff
vmov r9, r4
vshr r9, r8
vand r9, r10
vand r4, r10


vcrl 0x108, r5 ; set the control register which holds the value of the procedure called when timer interrupt is handled
voutb 0x71, r9 
voutb 0x71, r4 ; set the timer to our value
voutb 0x70, r1 ; activate the timer

; turn on maskable interrupts - they are off by default
vcrl 0x110, r1 

; hang the program until the timer is working
loop:
vinb 0x70, r10 
vand r10, r1
vcmp r10, r6
vjne loop
voff

interrupt_handler:
vset r10, 'U'
voutb 0x20, r10
vset r10, 'P'
voutb 0x20, r10
vset r10, '!'
voutb 0x20, r10
voutb 0x70, r6 ; We have to zero the control register of PIT ourselves, although the book says it should be zeroed automatically
viret ; return from handing an interrupt

