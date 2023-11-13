.include "m2560def.inc"

; ////////////////// REGISTER MAPPINGS /////////////////////

.def flightDirection = r3   ; register for flight direction
.def hfState = r4           ; register for flight state
.def speed = r20            ; permanent register for speed
.def temp1 = r21            ; working register 1
.def temp2 = r22            ; working register 2
.def temp3 = r23            ; working register 3
.def iH = r25
.def iL = r24


; //////////////////////////////////////////////////////////


/* 
/////////////////////////// LED ////////////////////////////

PATTERN_1 and PATTERN_2 are the LED patterns to be displayed.

////////////////////////////////////////////////////////////
*/
.equ PATTERN_1 = 0b10101010
.equ PATTERN_2 = 0b01010101

/* 
////////////////////////// KEYPAD //////////////////////////
Port F is used for keypad, high 4 bits for column selection.
Low four bits for reading rows.

On the board, RF7-4 connect to C3-0, RF3-0 connect to R3-0.

Key mappings:
    north = 2, 
    east = 6, 
    south = 8, 
    west = 4, 
    up = A, 
    down = B, 
    state change = C 

-	N	-	 up			|	1	2	3	A
w	-	E	down		|	4	5	6	B
-	S	-	 SC			|	7	8	9	C
-	-	-	 --			|	*	0	#	D	
////////////////////////////////////////////////////////////
*/

.def row    = r16				; current row number
.def col    = r17				; current column number
.def rmask  = r18				; mask for current row
.def cmask	= r19				; mask for current column

.equ KEYPAD_PORTDIR = 0xF0		; use PortL for input/output from keypad: PF7-4, output, PF3-0, input
.equ INITCOLMASK = 0xEF			; scan from the leftmost column, the value to mask output. 0xEF = 0b11101111 
.equ INITROWMASK = 0x01			; scan from the top row. 0x01 = 0b00000001
.equ ROWMASK  = 0x0F			; low four bits are output from the keypad. This value mask the high 4 bits. 0x0F = 0b00001111

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4

.equ LCD_RS = 7                 ; LCD_RS equal to 7        
.equ LCD_E = 6                  ; LCD_E equal to 6
.equ LCD_RW = 5                 ; LCD_RW equal to 5
.equ LCD_BE = 4                  ; LCD_BE equal to 4

; ////////////////// DIRECTION DEFINITIONS //////////////////
/* 

    north = 2, 
    east = 6,
    south = 8,
    west = 4,
    up = A,
    down = B,
    state change = C

    1   2   3   A   |   	-	N	-	 up			|	-	50	-	65
    4   5   6   B   |   	W	-	E	down		|	52	-	54	66
    7   8   9   C   |   	-	S	-	 SC			|	-	56	-   67	
    *   0   #   D   |   	-	-	-	 --			|	-	-	-   -	
*/
.equ NORTH_KEY = 50
.equ WEST_KEY = 52
.equ EAST_KEY = 54
.equ SOUTH_KEY = 56
.equ UP_KEY = 65
.equ DOWN_KEY = 66
.equ STATE_CHANGE_KEY = 67

.equ NORTH = 78
.equ WEST = 87
.equ EAST = 69 
.equ SOUTH = 83
.equ UP = 85
.equ DOWN = 68

; Reset and initialise board
rjmp RESET

.macro lcd_set
	sbi PORTA, @0                   ; set pin @0 of port A to 1
.endmacro
.macro lcd_clr
	cbi PORTA, @0                   ; clear pin @0 of port A to 0
.endmacro

.macro wait
    push temp1
	ser temp1
wait_loop:
	dec temp1
	tst temp1
	breq wait_end
	rcall sleep_1ms
	rjmp wait_loop
wait_end:
    pop temp1
	nop
.endmacro

/* 
    Flash Macro
    @0 - the number of times a flash should occur on the LED
*/
.macro flash_n_times
push temp1
clr temp1
flash_loop:
	cpi temp1, @0
	breq end_flash_loop
	rcall flash_led
	inc temp1
	rjmp flash_loop
end_flash_loop:
    pop temp1
.endmacro

/* 
    Flash LED 
    Displays PATTERN_1 and PATTERN_2 on the LED in an alternating pattern
*/
flash_led:
	push temp1
	ldi temp1, PATTERN_1
	out portc, temp1
	ldi temp1, 2
	out portg, temp1
	wait
	ldi temp1, PATTERN_2
	out portc, temp1
	ldi temp1, 1
	out portg, temp1
	wait
	pop temp1
	ret

; func of sleep 1ms
sleep_1ms:
    push iL
    push iH
    ldi iH, high(DELAY_1MS)
    ldi iL, low(DELAY_1MS)

delayloop_1ms:
    sbiw iH:iL, 1
    brne delayloop_1ms

    pop iH
    pop iL
    ret

sleep_5ms:                                    ; sleep 5ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	ret

.macro do_lcd_command           ; transfer command to LCD
	push r16
	ldi r16, @0                
	rcall lcd_command           
	rcall lcd_wait              
	pop r16
.endmacro

.macro do_lcd_data				; transfer data to LCD
	push r16
	ldi r16, @0                 
	rcall lcd_data              
	rcall lcd_wait       
	pop r16
.endmacro

.macro do_lcd_data_reg			; transfer data to LCD
	push r16
	mov r16, @0                 
	rcall lcd_data              
	rcall lcd_wait   
	pop r16     
.endmacro

RESET:
    ; reset all registers
    clr flightDirection
    clr hfState
    clr speed
    clr temp1
    clr temp2
    clr temp3
	clr row
	clr col
    clr iH
    clr IL

	ldi temp1, KEYPAD_PORTDIR				; Port L columns are outputs, rows are inputs  init rows = 0000(inputs) cols = 1111(outputs)
	sts	DDRL, temp1							; save temp1(00001111) to DDRL so that cols are outputs and rows are inputs

	; LCD initalization
	ser temp1						; set r16 to 0xFF
	out DDRF, temp1					; set PORT F to input mode
	out DDRA, temp1					; set PORT A to input mode
	clr temp1						; clear r16
	out PORTF, temp1					; out 0x00 to PORT F
	out PORTA, temp1					; out 0x00 to PORT A

	do_lcd_command 0b00111000		; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000		; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000		; 2x5x7
	do_lcd_command 0b00111000		; 2x5x7
	do_lcd_command 0b00001001		; display off
	do_lcd_command 0b00000001		; clear display
	do_lcd_command 0b00000110		; increment, no display shift
	do_lcd_command 0b00001111		; Cursor on, bar, blink

    ; initialise input push button
    cbi ddrd, 0								;pb0
    cbi ddrd, 1								;pb1

    ; initialise LED outputs
    ser temp1
    out ddrc, temp1
    out ddrg, temp1

    ; initialise speed register
	ldi speed, 1							; set init speed as 1

    ; initialise flying state
    ;   0: Flight
    ;   1: Hover 
    ldi temp1, 0x00
	mov hfState, temp1
    rjmp main

; ////////// THIS SECTION NEEDS TO BE MOVED INTO THE MAIN LOOP ////////
keypad_main:
	ldi cmask, INITCOLMASK		; initial column mask
	clr	col						; initial column
	clr row
colloop:
	cpi col, 4
	breq keypad_main
	sts	PORTL, CMASK			; set column to mask value (one column off)
	ldi temp1, 0xFF             ; initialise delay of 256 operations
delay:
	dec temp1					; decrease temp1
	brne delay					; if temp1 != 0, jump to delay, otherwise continue
    lds temp1, PINL				; read PORTL
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
	and temp2, RMASK			; check masked bit
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
	ldi temp2, 48				; convert decimal to their ascii values, actual value + ascii shift (48)
	add temp1, temp2		
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
	jmp convert_end


convert_end:
	cpi temp1, NORTH_KEY
	breq handle_north
	cpi	temp1, WEST_KEY
	breq handle_west
	cpi temp1, EAST_KEY 
	breq handle_east
	cpi temp1, SOUTH_KEY
	breq handle_south
	cpi	temp1, UP_KEY
	breq handle_up
	cpi	temp1, DOWN_KEY 
	breq handle_down
	cpi temp1, STATE_CHANGE_KEY
	breq handle_state_change
	rjmp keypad_main


handle_north:
	ldi temp1, NORTH						; load ascii value of "N"
	mov flightdirection, temp1				; set flight direction to north
    rjmp end_change
handle_west:
	ldi temp1, WEST							; load ascii value of "W"
	mov flightdirection, temp1				; set flight direction to west
    rjmp end_change
handle_east:
	ldi temp1, EAST							; load ascii value of "E"
	mov flightdirection, temp1				; set flight direction to east
    rjmp end_change
handle_south:
	ldi temp1, SOUTH						; load ascii value of "S"
	mov flightdirection, temp1				; set flight direction to south
    rjmp end_change
handle_up:
	ldi temp1, UP						    ; load ascii value of "U"
	mov flightdirection, temp1			    ; set flight direction to up
    rjmp end_change
handle_down:
	ldi temp1, DOWN						    ; load ascii value of "D"
	mov flightdirection, temp1				; set flight direction to down
    rjmp end_change
handle_state_change:
	mov temp1, hfState						; save the current state
	ldi temp2, 0xFF
	eor temp1, temp2
	mov hfState, temp1
end_change:
	clr row
    clr temp1
    clr temp2
	wait
    rjmp keypad_main
;/////////////////////////////////////////////////////////////////////////////////////

main:
	jmp keypad_main

;
; Send a command to the LCD (r16)
;

lcd_command:                        ; send a command to LCD IR
	out PORTF, r16
	nop
	lcd_set LCD_E                   ; use macro lcd_set to set pin 7 of port A to 1
	nop
	nop
	nop
	lcd_clr LCD_E                   ; use macro lcd_clr to clear pin 7 of port A to 0
	nop
	nop
	nop
	ret

lcd_data:                           ; send a data to LCD DR
	out PORTF, r16                  ; output r16 to port F
	lcd_set LCD_RS                  ; use macro lcd_set to set pin 7 of port A to 1
	nop
	nop
	nop
	lcd_set LCD_E                   ; use macro lcd_set to set pin 6 of port A to 1
	nop
	nop
	nop
	lcd_clr LCD_E                   ; use macro lcd_clr to clear pin 6 of port A to 0
	nop
	nop
	nop
	lcd_clr LCD_RS                  ; use macro lcd_clr to clear pin 7 of port A to 0
	ret

lcd_wait:                            ; LCD busy wait
	push r16                         ; push r16 into stack
	clr r16                         ; clear r16
	out DDRF, r16                    ; set port F to output mode
	out PORTF, r16                   ; output 0x00 in port F 
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E                    ; use macro lcd_set to set pin 6 of port A to 1
	nop
	nop
    nop
	in r16, PINF                     ; read data from port F to r16
	lcd_clr LCD_E                    ; use macro lcd_clr to clear pin 6 of port A to 0
	sbrc r16, 7                      ; Skip if Bit 7 in R16 is Cleared
	rjmp lcd_wait_loop               ; rjmp to lcd_wait_loop
	lcd_clr LCD_RW                   ; use macro lcd_clr to clear pin 7 of port A to 0
	ser r16                          ; set r16 to 0xFF
	out DDRF, r16                   ; set port F to input mode
	pop r16                          ; pop r16 from stack
	ret

