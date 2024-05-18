%include "vm.inc"
  ; 1. Make a loop which will input a number to r6 and r7.
  ; 2. Use an instruction for adding two registers
  ; 3. Call a subroutine to print a number
  ; This program supports up to eight digits (2^32 has 10 digits so in order to avoid an overflow we must limit it, it could be 9 easily, but my input_number implentation is weird).

vset r4, first_number ; That is how you print a number. First set r4 to adress, then call print
vcall print

vset r8, 0x30 ; a constant needed for ascii-to-number conversion
vset r9, 0xA  ; ascii code for the line feed character also a decimal 10, which is the number we modulo by 
vset r10, 0x1 ; the number we bit-shift by 

vxor r6, r6 ; before calling input_number we must zero the r5 register, this is suboptimal
vcall input_number

vmov r7, r6

vset r4, second_number
vcall print

vxor r6, r6
vcall input_number


vmov r11, r6
vadd r11, r7
vcall output_result ; the result is going to be stored in r11
vjmp end; end of the program

output_result:
  ; we divide r12 by 10 ^ (n - 1), to get n-th digit
  ; we have r0..r13 are general purpose registers
  ; r12 is going to store the ascii code of the current char to be printed
  vset r13, 1000000000 ; change this to change the number of printed digits

  .output_loop:
  vxor r4, r4
  vcmp r13, r3
  vjz .return_output

  vmov r12, r11
  vdiv r12, r13
  vadd r12, r8 ; conversion from number back to ascii
  voutb 0x20, r12
  vmod r11, r13 ; we cut off the last digit
  vdiv r13, r9 ; we divide r13 to move to the n-th - 1 digit
  vjmp .output_loop

  .return_output:
  voutb 0x20, r9 ; printf("\n") equivalent
  vret


input_number:
  vinb 0x20, r5 ; input byte also reads the line feed character, which is good

  vcmp r5, r9 ; if we encounter a newline, the number input is done
  vjz return_input

  vsub r5, r8 ; convert char to number
  vadd r6, r5
  vmul r6, r9

  vjmp input_number

return_input:
  vdiv r6, r9
  vret

print:
  ; Procedure for printing string at r4
  vxor r0, r0 ; Set r0 to all zeroes
  vset r1, 1 ; The counter on which char we are currently printing
  vcall print_loop
  vret
print_loop:
  ; Pobierz bajt spod adresu z R0.
  vldb r2, r4

  ; Jesli to zero, wyjdź z pętli.
  vcmp r2, r0
  vjz return 

  ; W przeciwym wypadku, wypisz znak na konsoli.
  voutb 0x20, r2

  ; Przesuń r4 na kolejny znak i idź na początek pętli.
  vadd r4, r1
  vjmp print_loop

end:
 ; Koniec.
voff

return:
 ; return from function, we need something like this because you can't just write "vjz vret"
vret

first_number:
  db "Wprowadz pierwsza liczbe: ", 0xa, 0

second_number:
  db "Wprowadz druga liczbe: ", 0xa, 0

result:
  db "Wynik to: ", 0xa, 0
