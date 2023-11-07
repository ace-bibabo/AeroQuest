;
; COMP9032 term project.asm
;
; Created: 2023/11/6 10:55:00
; Author : talln
;


.include "m2560def.inc"

; keyboard operation, part comes from Annie's sample code 1
; Port F is used for keypad, high 4 bits for column selection, low four bits for reading rows. On the board, RF7-4 connect to C3-0, RF3-0 connect to R3-0.
; north = 2, east = 6, south = 8, west = 4, up = A, down = B, state change = C 
;	-	N	-	 up			|	1	2	3	A
;	w	-	E	down		|	4	5	6	B
;	-	S	-	 SC			|	7	8	9	C
;	-	-	-	 --			|	*	0	#	D	
.def row    =r16		; current row number
.def col    =r19		; current column number
.def rmask  =r20		; mask for current row
.def cmask	=r21		; mask for current column
.def temp1	=r22		
.def temp2  =r23

.equ PORTFDIR =0xF0			; use PortF for input/output from keypad: PF7-4, output, PF3-0, input. 0xF0 = 0b11110000
.equ INITCOLMASK = 0xEF		; scan from the leftmost column, the value to mask output. 0xEF = 0b11101111 
.equ INITROWMASK = 0x01		; scan from the top row. 0x01 = 0b00000001
.equ ROWMASK  =0x0F			; low four bits are output from the keypad. This value mask the high 4 bits. 0x0F = 0b00001111

;rjmp	RESET
RESET:
	ldi temp1, PORTFDIR			; columns are outputs, rows are inputs
	out	DDRF, temp1

main:
	ldi cmask, INITCOLMASK		; initial column mask
	clr	col						; initial column
colloop:
	cpi col, 4
	breq main
	out	PORTF, cmask			; set column to mask value (one column off)
	ldi temp1, 0xFF
delay:
	dec temp1					; decrease temp1
	brne delay					; if temp1 != 0, jump to delay, otherwise continue 

	in	temp1, PINF				; read PORTF
	andi temp1, ROWMASK
	cpi temp1, 0xF				; check if any rows are on
	breq nextcol
								; if yes, find which row is on
	ldi rmask, INITROWMASK		; initialise row check
	clr	row						; initial row
rowloop:
	cpi row, 4
	breq nextcol
	mov temp2, temp1
	and temp2, rmask			; check masked bit
	breq convert 				; if bit is clear, convert the bitcode
	inc row						; else move to the next row
	lsl rmask					; shift the mask to the next bit
	jmp rowloop

nextcol:
	lsl cmask					; else get new mask by shifting and 
	inc col						; increment column value
	jmp colloop					; and check the next column

convert:
	cpi col, 3					; if column is 3 we have a letter
	breq letters				
	cpi row, 3					; if row is 3 we have a symbol or 0
	breq symbols

	mov temp1, row				; otherwise we have a number in 1-9
	lsl temp1
	add temp1, row				; temp1 = row * 3
	add temp1, col				; add the column address to get the value
	inc temp1					; actual value = row * c + column + 1
	ldi temp2,48				; convert decimal to their ascii values, actual value + ascii shift (48)
	add temp1,temp2				
	jmp convert_end

letters:
	ldi temp1, 65				; load Ascii value of 'A' 65
	add temp1, row				; increment the character 'A' by the row value
	jmp convert_end

symbols:
	cpi col, 0					; check if we have a star
	breq star
	cpi col, 1					; or if we have zero
	breq zero					
	ldi temp1, 35				; if not we have hash, load ascii value of hash (35)
	jmp convert_end
star:
	ldi temp1, 42				; set to ascii value of star (42)
	jmp convert_end
zero:
	ldi temp1, 48				; set to ascii value of '0' (48)


; north = 2, east = 6, south = 8, west = 4, up = A, down = B, state change = C 
;	-	N	-	 up			|	1	2	3	A
;	w	-	E	down		|	4	5	6	B
;	-	S	-	 SC			|	7	8	9	C
;	-	-	-	 --			|	*	0	#	D	
convert_end:
	cpi temp1,50
	breq north
	cpi	temp1,52
	breq west
	cpi temp1,54
	breq east
	cpi temp1,56
	breq south
	cpi	temp1,65
	breq up
	cpi	temp1,66
	breq down
	cpi temp1,67
	breq statechange

; function waiting to be implemented
north:

west:

east:

south:

up:

down:

statechange: