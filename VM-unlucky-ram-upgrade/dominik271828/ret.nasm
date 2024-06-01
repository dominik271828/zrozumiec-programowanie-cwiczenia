%include "vm.inc"
; we use the fact, that vret instruction doesn't do modulo 2^16 when jumping
; this code, when you upgrade the amount of memory to 1MB (and also upgrade reading the rom to at most 1MB) prints A
; although the instructions are beyond the correct memory address
vset r0, 0x10000
vpush r0
vret
TIMES 0xfff7 db 0xFF
vset r1, 'A'
voutb 0x20, r1
voff
