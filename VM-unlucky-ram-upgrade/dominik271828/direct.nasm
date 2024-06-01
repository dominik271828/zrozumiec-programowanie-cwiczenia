%include "vm.inc"
; we can of course just set the pc directly via vset lmao
vset r15, 0x10000
TIMES 0xfffa db 0xFF
vset r1, 'A'
voutb 0x20, r1
voff
