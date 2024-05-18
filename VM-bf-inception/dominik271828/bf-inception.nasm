%include "vm.inc"
; The program will be inputed in the first line of input, the program file needs to have a \n at the end of the code
; We need to store the program in ram, because loops need to go back in code
; I will implement everything before implementing the loops, those are the hardest part
; FETCHING:
;	LOAD ALL INTO MEMORY
;	REVERT THE PC TO THE ORIGINAL POSITION
;	START PROCESSING THE PROGRAM WITH THE EXECUTE PROCEDURE

vset r10, 0xA000 ; adress of the current instruction (PC) 
vset r13, 0xF000 ; memory pointer
vcall set_registers

fetch:
vinb 0x20, r0 ; fetch one byte from stdin
vcmp r0, r1 ; if we encounter a newline, jump to decode
vjz decode
vstb r10, r0 ; save the byte in memory
vadd r10, r11 ; increment the adress of the free memory
;voutb 0x20, r0 ; output the byte 
vjmp fetch

decode:
vset r10, 0xA000 ; revert the PC back to the start of the program
.loop:
vxor r12, r12
vldb r0, r10
vcmp r0, r12
vjz .end
vcall execute
vadd r10, r11
vjmp .loop

.end:
voff ; end of program


set_registers:
vset r1, 0xA  ; '\n' char
vset r2, 0x3C ; '<' char
vset r3, 0x3E ; '>' char
vset r4, 0x2E ; '.' char
vset r5, 0x2C ; ',' char
vset r6, 0x2B ; '+' char
vset r7, 0x2D ; '-' char
vset r8, 0x5B ; '[' char
vset r9, 0x5D ; ']' char
vset r11, 0x1 ; used for incrementing/decrementing values
vret

execute: ; r0 stores the current instruction to be processed, if we reach a zero in memory instead of an instruction, the loop will terminate, which is good
vcall set_registers
vcmp r0, r2
vjz shift_left
vcmp r0, r3
vjz shift_right
vcmp r0, r4
vjz print_cell
vcmp r0, r5
vjz get_input
vcmp r0, r6
vjz add_cell
vcmp r0, r7
vjz sub_cell
vcmp r0, r8
vjz loop_begin
vcmp r0, r9
vjz loop_end
.end_execute:
vret

shift_left: ; decrement the memory pointer
vsub r13, r11
vjmp execute.end_execute

shift_right: ; increment the memory pointer
vadd r13, r11
vjmp execute.end_execute

print_cell: ; print the current byte pointed by the memory pointer as ascii
vldb r12, r13 ; load the byte at memory adress
voutb 0x20, r12 ; push the byte to console
vjmp execute.end_execute

get_input:
vinb 0x20, r12 ; get one byte from user
vstb r13, r12 ; set the memory cell to user input
vjmp execute.end_execute

add_cell:
vldb r12, r13 ; load the byte
vadd r12, r11 ; increment 
vstb r13, r12 ; set the memory to user input
vjmp execute.end_execute

sub_cell:
vldb r12, r13 ; load the byte
vsub r12, r11 ; decrement
vstb r13, r12 ; set the memory to user input
vjmp execute.end_execute

loop_begin: 
; IF *memory_pointer == 0 THEN
; 	JUMP TO THE MATCHING ']' 
; we can use r0 here, since we are already after the jump
vxor r12, r12
vldb r0, r13
vcmp r0, r12
vjz skip_loop_begin
vjmp execute.end_execute


skip_loop_begin: ; r12 will be the counter, program counter points at the current instruction!! memory_pointer point at the current cell!!
; program_counter += 1
; WHILE r12 > 0 OR *program_counter != ']' DO
; 	IF *program_counter == '[' THEN
;		r12 += 1
;	IF *program_counter == ']' THEN
;		r12 -= 1
;	program_counter += 1
vadd r10, r11 ; program_counter += 1
vxor r1, r1 ; r1 = 0

.while:
vldb r0, r10
vcmp r0, r9 ; *program_counter == ']' ; 
vjz .second_condition
.endcheck:

vcmp r0, r8 ; *program_counter == '['
vjz .increment_counter
vcmp r0, r9 ; *program_counter == ']'
vjz .decrement_counter
.endif:

vadd r10, r11
vjmp .while
.end:
vjmp execute.end_execute ; the processing of the instruction is over, we can move on to the next instruction

.second_condition:
vcmp r12, r1 ; r12 == 0
vjz .end
vjmp .endcheck

.increment_counter:
vadd r12, r11
vjmp .endif 

.decrement_counter:
vsub r12, r11
vjmp .endif

loop_end:
; IF *memory_pointer != 0 THEN
; 	JUMP TO THE MATCHING '[' 
; we can use r0 here, since we are already after the jump
vxor r12,r12
vldb r0, r13
vcmp r0, r12 ; if the current cell is not 0, jump
vjnz skip_loop_end
vjmp execute.end_execute

skip_loop_end: ; r13 - memory pointer, r10 - program counter, r12 - brackets counter
; program_counter -= 1
; WHILE r12 > 0 OR *program_counter != '[' DO
; 	IF *program_counter == ']' THEN
;		r12 += 1
;	IF *program_counter == '[' THEN
;		r12 -= 1
;	program_counter -= 1

vsub r10, r11 ; program_counter -= 1
vxor r1, r1 ; r1 = 0

.while:
vldb r0, r10
vcmp r0, r8 ; *program_counter == '[' ; 
vjz .second_condition
.endcheck:

vcmp r0, r9 ; *program_counter == ']'
vjz .increment_counter
vcmp r0, r8 ; *program_counter == '['
vjz .decrement_counter
.endif:

vsub r10, r11
vjmp .while
.end:
vjmp execute.end_execute ; the processing of the instruction is over, we can move on to the next instruction

.second_condition:
vcmp r12, r1 ; r12 == 0
vjz .end
vjmp .endcheck

.increment_counter:
vadd r12, r11
vjmp .endif 

.decrement_counter:
vsub r12, r11
vjmp .endif
