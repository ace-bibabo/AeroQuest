.include "m2560def.inc"

; ////////////////// REGISTER MAPPINGS /////////////////////

.def flightDirection = r3   ; register for flight direction
.def hfState = r4           ; register for flight state
.def pos_x = r5				; register for x position
.def pos_y = r6				; register for y position
.def pos_z = r7				; register for z position
.def counter_speed = r8		; register for updating speed information
.def func_return = r9       ; stores the result of a func_return
.def func_return2 = r10
.def acci_loc_x = r11
.def acci_loc_y = r12
.def acci_loc_z = r13
.def visibility = r14
.def speed = r20            ; permanent register for speed
.def temp1 = r21            ; working register 1
.def temp2 = r22            ; working register 2
.def temp3 = r23            ; working register 3
.def iL = r24
.def iH = r25

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

.equ FLIGHT = 'F'
.equ HOVER = 'H'
.equ RETURN = 'R'
.equ CRASH = 'C'

.equ MAPSIZE = 15
;;;;;;;;;;;;;;;;;interrupt;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.cseg
.org 0x00
jmp RESET
.org OVF0addr
	jmp Timer0OVF ; Timer overflow interrupt
.org OVF2addr
	jmp Timer0OVF ; Timer overflow interrupt

; Define a 15x15 matrix with all elements initialized to 1
.org 0x50
matrix_addr:
.db 1, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 7, 6, 7, 8
.db 2, 8, 7, 6, 5, 4, 2, 2, 3, 4, 5, 6, 4, 3, 2
.db 4, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 5, 6, 7
.db 5, 7, 6, 5, 4, 3, 2, 3, 4, 5, 6, 7, 5, 4, 3
.db 6, 4, 5, 6, 7, 8, 7, 8, 5, 4, 3, 2, 4, 5, 6
.db 2, 8, 5, 4, 3, 2, 3, 4, 5, 6, 7, 8, 5, 6, 7
.db 2, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 7, 6, 7, 8
.db 2, 8, 7, 6, 5, 4, 2, 2, 3, 4, 5, 6, 4, 3, 2
.db 2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 5, 6, 7
.db 8, 7, 6, 5, 4, 3, 2, 3, 4, 5, 6, 7, 5, 4, 3
.db 3, 4, 5, 6, 7, 8, 7, 8, 5, 4, 3, 2, 4, 5, 6
.db 7, 8, 5, 4, 3, 2, 3, 4, 5, 6, 7, 8, 5, 6, 7
.db 7, 8, 5, 4, 3, 2, 3, 4, 5, 6, 7, 8, 5, 6, 7
.db 2, 2, 3, 4, 5, 6, 2, 3, 4, 5, 6, 7, 6, 7, 8
.db 9, 8, 7, 6, 5, 4, 2, 2, 3, 4, 5, 6, 4, 3, 2

;;;;;;;;;;;;;;;;;;;macro wait 256ms;;;;;;;;;;;;;;;;;;;;;
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
	nop
	pop temp1
.endmacro

.macro led_display
	push temp1
	ser temp1
	ser temp1
	out ddrc, temp1 ;
	out portc, @0
	wait
end_display:
	nop	
	pop temp1
.endmacro

.macro do_lcd_command           ; transfer command to LCD

	ldi r16, @0                
	rcall lcd_command           
	rcall lcd_wait              

.endmacro

.macro do_lcd_command_reg           ; transfer command to LCD

	mov r16, @0                
	rcall lcd_command           
	rcall lcd_wait              
 
.endmacro
 
.macro do_lcd_data				; transfer data to LCD

	ldi r16, @0                 
	rcall lcd_data              
	rcall lcd_wait              

.endmacro
 
.macro do_lcd_data_reg			; transfer data to LCD
    push r16
	mov r16, @0                 
	rcall lcd_data              
	rcall lcd_wait              
    pop r16
.endmacro

.macro check_location
	cp @0, acci_loc_x
	brne jmp_end_location
	cp @1, acci_loc_y
	brne jmp_end_location
	cp @2, acci_loc_z
	brne jmp_end_location
	rjmp found_display
jmp_end_location:
	jmp end_check_location
found_display:
	do_lcd_command 0x01
	do_lcd_command (0x80 | 0x40)
	do_lcd_data 'R'
	do_lcd_command (0x80 | 0x44)
	do_lcd_data '('
	send_digits_to_lcd @0
	do_lcd_data ','
	send_digits_to_lcd @1
	do_lcd_data ','
	send_digits_to_lcd @2
	do_lcd_data ')'
	wait
	rjmp found_display
end_check_location:
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
	cbi portg, 0
	led_display speed
.endmacro

; @0 x-pos, @1 y-pos
.macro z_from_x_y
	push r16
	push r17
	push ZL
	push ZH
	ldi ZL, low(matrix_addr<<1)
	ldi ZH, high(matrix_addr<<1)
	clr r16
	ldi r16, MAPSIZE + 1
	mul @1, r16 ; Multiply row index by row width to get offset
	add ZL, r0 ; Add the offset to the Z pointer
	adc ZH, r1
	clr r17
	add ZL, @0 ; Calculate the offset for the column
	adc ZH, r17
	lpm func_return, Z
	pop ZH
	pop ZL
	pop r17
	pop r16
.endmacro

.macro divide_reg
	push r18
	push r19
    ldi r18, 0        ; Initialize quotient to 0
    ldi r19, 0        ; Clear counter
divide_loop:
    cp @0, @1
    brlo end_divide   ; If numerator < denominator, branch to end
    sub @0, @1      ; Subtract denominator from numerator
    inc r18  
    rjmp divide_loop  ; Repeat until numerator < denominator
end_divide:
	mov @0, r18
    pop r19
	pop r18
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

load_map:
	push temp1
	push temp2
	push temp3
	push ZL
	push ZH

	clr temp1
	clr temp2
	clr temp3

	ldi ZL, low(matrix_addr<<1)
	ldi ZH, high(matrix_addr<<1)
	mov temp1, flightDirection
	
	cpi temp1, NORTH
	breq load_column
	cpi temp1, SOUTH
	breq load_column
	cpi temp1, EAST
	breq load_row
	cpi temp1, WEST
	breq load_row
	rjmp end_load_map
load_row:
    ; Calculate the offset for the row (each row is MAPSIZE bytes wide)
    ldi temp1, MAPSIZE + 1
    mul pos_y, temp1 ; Multiply row index by row width to get offset
    ; Add the offset to the Z pointer
    add ZL, r0
    adc ZH, r1
	ldi temp1, MAPSIZE
    rjmp display_loop

load_column:
    ; Calculate the offset for the column
    ; In this case, we add the column index to the base address
    ; and then add size of map to Z for each iteration to move down the column
	clr temp2
	add ZL, pos_x
	adc ZH, temp2
    ; Set the loop counter for size of map iterations
    ldi temp1, MAPSIZE
    rjmp display_column_loop

display_loop:
    lpm temp3, Z+ ; Load the value pointed by Z into r19 and increment Z
	subi temp3, -'0'
    do_lcd_data_reg temp3
    dec temp1
    brne display_loop
    rjmp end_load_map

display_column_loop:
    lpm temp3, Z ; Load the value pointed by Z into r19
	subi temp3, -'0'
	do_lcd_data_reg temp3
    adiw Z, MAPSIZE+1 ; Add size of map to Z to move to the next element in the column
    dec temp1
    brne display_column_loop
end_load_map:
	pop ZH
	pop ZL
	pop temp3
	pop temp2
	pop temp1
	ret

display_cursor:
	push temp2
	mov temp2, flightDirection
	cpi temp2, NORTH
	breq y_cursor
	cpi temp2, SOUTH
	breq y_cursor
	cpi temp2, EAST
	breq x_cursor
	cpi temp2, WEST
	breq x_cursor
	rjmp exit_cursor
x_cursor:
	mov temp2, pos_x  
	ori temp2, 0x80 
	do_lcd_command_reg temp2
	rjmp exit_cursor
y_cursor:
	mov temp2, pos_y
	ori temp2, 0x80 
	do_lcd_command_reg temp2
exit_cursor:
	pop temp2
	ret

; RESET
RESET:
    ; Initialize Stack Pointer
    ldi temp1, low(RAMEND)
    out SPL, temp1
    ldi temp1, high(RAMEND)
    out SPH, temp1

	; Set up switch
	clr temp1
	out DDRD, temp1
	ser temp1
	out PORTD, temp1

	; LCD initalization
	ser temp1                      ; set r16 to 0xFF
	out DDRF, temp1                ; set PORT F to input mode
	out DDRA, temp1                ; set PORT A to input mode
	clr temp1                      ; clear r16
	out PORTF, temp1               ; out 0x00 to PORT F
	out PORTA, temp1               ; out 0x00 to PORT A

	; Set up LCD
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001001 ; display off
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

    ; Set up timer overflow interrupt

	ldi temp1, 0b00000000
	out TCCR0A, temp1
	ldi temp1, 0b00000011
	out TCCR0B, temp1				; Prescaling value=64
	ldi temp1, 1<<TOIE0				; =1024 microseconds
	sts TIMSK0, temp1				; T/C0 interrupt enable

	ldi temp1, 0b00000000
	sts TCCR2A, temp1
	ldi temp1, 0b00000011
	sts TCCR2B, temp1				; Prescaling value=64
	ldi temp1, 1<<TOIE2				; =1024 microseconds
	sts TIMSK2, temp1				; T/C0 interrupt enable

	; Set up keypad 
	ldi temp1, KEYPAD_PORTDIR				; Port L columns are outputs, rows are inputs  init rows = 0000(inputs) cols = 1111(outputs)
	sts	DDRL, temp1							; save temp1(00001111) to DDRL so that cols are outputs and rows are inputs

	; Initialize variables
	ldi temp1, 0
	mov pos_x, temp1
	mov pos_y, temp1
	z_from_x_y pos_x, pos_y
	mov pos_z, func_return
	ldi speed, 0
	; Initialize visibility level
	ldi temp1, 4
	mov visibility, temp1
	ldi temp1, '-'
	mov hfState, temp1
	mov flightDirection, temp1
	
	; initialise LED outputs
    ser temp1
    out ddrc, temp1
    out ddrg, temp1

	clr r26
	clr r27
	clr r28
	clr r29
    clr speed
    clr temp1
    clr temp2
    clr temp3
    clr iH
    clr IL
	clr func_return

	cli

	jmp main

.macro send_digits_to_lcd
	push temp1
	push temp2
	mov temp1, @0
	cpi temp1, 10
	brlo send_ones_to_lcd
	brsh send_tens_to_lcd
	send_tens_to_lcd:
		do_lcd_data '1'
		subi temp1, 10
	send_ones_to_lcd:
		subi temp1, -'0'
		do_lcd_data_reg temp1
	pop temp2
	pop temp1
.endmacro
 
Timer0OVF:							; interrupt subroutine for Timer0
	push temp1
	in temp1, SREG ; save SREG
	push temp1
	push temp2
	push temp3
	adiw r27:r26, 1					; Increase the temporary counter by one.
	cpi r26, low(100)				; Check if (r25:r24)=244, overflows at 1000ms
    brne end_timer_rjmp
	cpi r27, high(100)				
	brne end_timer_rjmp
	inc counter_speed
	mov temp1, counter_speed
	ldi temp2, 100
	tst speed
	breq after_speed_scale
	divide_reg temp2, speed 
	cp temp1, temp2
	brsh handle_speed_rjmp
after_speed_scale:
	clr r26
	clr r27
	rjmp handle_display
	end_timer_rjmp:
		rjmp end_timer
	handle_speed_rjmp:
		rjmp handle_speed
	handle_display:
	do_lcd_command (0x80 | 0x00)
	rcall load_map
	do_lcd_command (0x80 | 0x40)
	do_lcd_data_reg hfState
	do_lcd_command (0x80 | 0x44)
	do_lcd_data '('
	send_digits_to_lcd pos_x
	do_lcd_data ','
	send_digits_to_lcd pos_y
	do_lcd_data ','
	send_digits_to_lcd pos_z
	do_lcd_data ')'
	do_lcd_command (0x80 | 0x4D)
	do_lcd_data_reg flightdirection
	do_lcd_data '/'
	subi speed, -'0'
	do_lcd_data_reg speed
	subi speed, '0'
	rcall display_cursor
end_timer:
	pop temp3
	pop temp2
	pop temp1 ; restore SREG
	out SREG, temp1
	pop temp1
	reti							; Return from the interrupt.

handle_speed:
	clr r26
	clr r27
	clr counter_speed
	mov temp1, flightDirection
	mov temp2, hfState

	cpi temp2, HOVER
	breq handle_hover_speed
	rjmp handle_flight_speed

handle_hover_speed:
	mov temp2, pos_z
	cpi temp1, UP
	breq go_up
go_down:
	; stops us from going below the current altitude
	z_from_x_y pos_x, pos_y
	cp func_return, temp2
	brsh lowest
	dec temp2
	rjmp exit_hover
lowest:
	mov temp2, func_return
	rjmp exit_hover
go_up:
	inc temp2
	cpi temp2, 10
	brlo exit_hover
	ldi temp2, 9
exit_hover:
	mov pos_z, temp2
	jmp search_accident_loc

handle_flight_speed:
	mov temp2, pos_x
	mov temp3, pos_y
	cpi speed, 0
	breq end_timer
	cpi temp1, NORTH
	breq go_north
	cpi temp1, SOUTH
	breq go_south
	cpi temp1, WEST
	breq go_west
go_east:
	inc temp2
	cpi temp2, 14
	brlo exit_flight_x
	ldi temp2, 14
	rjmp exit_flight_x
go_north:
	cpi temp3, 1
	brlo northest
	dec temp3
	rjmp exit_flight_y
northest:
	ldi temp3, 0
	rjmp exit_flight_y
go_south:
	inc temp3
	cpi temp3, 14
	brlo exit_flight_y
	ldi temp3, 14
	rjmp exit_flight_y
go_west:
	cpi temp2, 1
	brlo westest
	dec temp2
	rjmp exit_flight_x
westest:
	ldi temp2, 0
	rjmp exit_flight_x
exit_flight_x:
	mov pos_x, temp2
	rjmp crash_check
exit_flight_y:
	mov pos_y, temp3
	rjmp crash_check
crash_check:
	z_from_x_y pos_x, pos_y
	cp pos_z, func_return
	brlo auto_increase_z
	rjmp end_crash_check
auto_increase_z:
	inc pos_z
	cp pos_z, func_return
	breq end_crash_check
	rjmp crashed_display
end_crash_check:
	rjmp search_accident_loc
crashed_display:
	do_lcd_command 0x01
	do_lcd_command (0x80 | 0x40)
	do_lcd_data 'C'
	do_lcd_command (0x80 | 0x44)
	do_lcd_data '('
	send_digits_to_lcd pos_x
	do_lcd_data ','
	send_digits_to_lcd pos_y
	do_lcd_data ','
	send_digits_to_lcd pos_z
	do_lcd_data ')'
crashed:
	flash_n_times 2                                                     
	rjmp crashed
search_accident_loc:
	mov temp1, flightDirection
	mov temp3, visibility
	dec temp3
	cpi temp1, NORTH
	breq jmp_search_north
	cpi temp1, SOUTH
	breq jmp_search_south
	cpi temp1, WEST
	breq jmp_search_west
	cpi temp1, EAST
	breq search_east
	jmp search_east
jmp_search_north:
	jmp search_north
jmp_search_south:
	jmp search_south
jmp_search_west:
	jmp search_west
not_visible_0:
	jmp end_timer
jmp_skipped_search_east:
	jmp skipped_search_east
search_east:
	mov temp1, pos_x 
search_east_loop:
	tst temp3
	breq not_visible_0
	mov temp2, pos_z
	z_from_x_y temp1, pos_y
	cp temp2, func_return ; if there is a mountain between here and location, then it's not visible
	brlo not_visible_0
	sub temp2, func_return
	cp temp3, temp2  ; if groud is too far, then it's not visible
	brlo jmp_skipped_search_east 

	check_location temp1, pos_y, func_return

skipped_search_east:
	cpi temp1, 0	; if at the edge of bound, then it's not visible
	breq not_visible_1
	inc temp1 ; move in current direction
	dec temp3 ; decrease visibility
	rjmp search_east_loop
not_visible_1:
	jmp end_timer

jmp_skipped_search_west:
	jmp skipped_search_west
search_west:
	mov temp1, pos_x 
search_west_loop:
	tst temp3
	breq not_visible_1
	mov temp2, pos_z
	z_from_x_y temp1, pos_y
	cp temp2, func_return ; if there is a mountain between here and location, then it's not visible
	brlo not_visible_1
	sub temp2, func_return
	cp temp3, temp2  ; if groud is too far, then it's not visible
	brlo jmp_skipped_search_west 

	check_location temp1, pos_y, func_return

skipped_search_west:
	cpi temp1, 0	; if at the edge of bound, then it's not visible
	breq not_visible_2
	dec temp1 ; move in current direction
	dec temp3 ; decrease visibility
	rjmp search_west_loop
not_visible_2:
	jmp end_timer

jmp_skipped_search_south:
	jmp skipped_search_south
search_south:
	mov temp1, pos_y 
search_south_loop:
	tst temp3
	breq not_visible_2
	mov temp2, pos_z
	z_from_x_y pos_x, temp1
	cp temp2, func_return ; if there is a mountain between here and location, then it's not visible
	brlo not_visible_2
	sub temp2, func_return
	cp temp3, temp2  ; if groud is too far, then it's not visible
	brlo jmp_skipped_search_south 

	check_location pos_x, temp1, func_return

skipped_search_south:
	cpi temp1, 14	; if at the edge of bound, then it's not visible
	breq not_visible_3
	inc temp1 ; move in current direction
	dec temp3 ; decrease visibility
	rjmp search_south_loop
not_visible_3:
	jmp end_timer

jmp_skipped_search_north:
	jmp skipped_search_north
search_north:
	mov temp1, pos_y 
search_north_loop:
	tst temp3
	breq not_visible_3
	mov temp2, pos_z
	z_from_x_y pos_x, temp1
	cp temp2, func_return ; if there is a mountain between here and location, then it's not visible
	brlo not_visible_3
	sub temp2, func_return
	cp temp3, temp2  ; if groud is too far, then it's not visible
	brlo jmp_skipped_search_north

	check_location pos_x, temp1, func_return
	
skipped_search_north:
	cpi temp1, 0	; if at the edge of bound, then it's not visible
	breq not_visible_4
	dec temp1 ; move in current direction
	dec temp3 ; decrease visibility
	rjmp search_north_loop
not_visible_4:
	jmp end_timer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Keypad;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;o_check_buttons:
;	pop row
;	pop col
;	jmp check_buttons
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; calls keypad_main which stores a value in func_return (r9)
.macro get_input
    push temp1
    rcall keypad_main
    pop temp1
.endmacro

keypad_main:
	push col
	push row
	push temp1
    push temp2
	clr temp1
	ldi cmask, INITCOLMASK		; initial column mask
	clr	col						; initial column
	clr row
colloop:
	cpi col, 4
	breq return_from_keypad                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
	rcall handle_speed_change
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
    rjmp return_from_keypad
letters:
	ldi temp1, 65				; load Ascii value of 'A' 65
	add temp1, row				; increment the character 'A' by the row value
    rjmp return_from_keypad
symbols:
	cpi col, 0					; check if we have a star
	breq star
	cpi col, 1					; or if we have zero
	breq zero
	ldi temp1, 35				; if not we have hash, load ascii value of hash (35)
    rjmp return_from_keypad
star:
	ldi temp1, 42				; set to ascii value of star (42)
    rjmp return_from_keypad
zero:
	ldi temp1, 48				; set to ascii value of '0' (48)
return_from_keypad:
	cpi col, 4					; if we've reached the end, then no input was provided
	breq return_empty_val
    mov func_return, temp1
	pop temp2
	pop temp1
    pop row
    pop col
    ret
return_empty_val:
	clr temp1
	mov func_return, temp1
	pop temp2
	pop temp1
    pop row
    pop col
	ret 

.macro handle_input
	push r16
	mov r16, func_return
    rcall handle_input_func
	pop r16
.endmacro

handle_input_func:
	push temp1
	push temp2
	mov temp2, hfState
	cpi temp2, 'F'
	breq go_state_change
	cpi r16, NORTH_KEY
	breq handle_north
	cpi	r16, WEST_KEY
	breq handle_west
	cpi r16, EAST_KEY 
	breq handle_east
	cpi r16, SOUTH_KEY
	breq handle_south
	cpi	r16, UP_KEY
	breq handle_up
	cpi	r16, DOWN_KEY 
	breq handle_down
go_state_change:
	cpi r16, STATE_CHANGE_KEY
	breq handle_state_change
	rjmp end_change
handle_north:
	ldi temp1, NORTH						; load ascii value of "N"
	mov flightdirection, temp1				; set flight direction to north
    rjmp end_change_cardinal
handle_west:
	ldi temp1, WEST							; load ascii value of "W"
	mov flightdirection, temp1				; set flight direction to west
    rjmp end_change_cardinal
handle_east:
	ldi temp1, EAST							; load ascii value of "E"
	mov flightdirection, temp1				; set flight direction to east
    rjmp end_change_cardinal
handle_south:
	ldi temp1, SOUTH						; load ascii value of "S"
	mov flightdirection, temp1				; set flight direction to south
    rjmp end_change_cardinal
handle_up:
	ldi temp1, UP						    ; load ascii value of "U"
	mov flightdirection, temp1			    ; set flight direction to up
    rjmp end_change_cardinal
handle_down:
	ldi temp1, DOWN						    ; load ascii value of "D"
	mov flightdirection, temp1				; set flight direction to down
    rjmp end_change_cardinal
handle_state_change:
	mov temp1, hfState						; save the current state
	cpi temp1, HOVER
	breq handle_hover
handle_flight_or_null:
	ldi temp1, HOVER
	mov hfState, temp1
	ldi speed, 0
	rjmp end_change
handle_hover:
	ldi temp1, FLIGHT
	mov hfState, temp1
	ldi speed, 0
end_change_cardinal:
	ldi speed, 0         
end_change:
	wait
	pop temp2
	pop temp1
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;LCD functions;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
	clr r16                          ; clear r16
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
	out DDRF, r16                    ; set port F to input mode
	pop r16                          ; pop r16 from stack
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
return_from_speed_change:
	pop temp2
	pop temp1
	ret

handle_speed_change:
	push temp1
	push temp2
	mov temp1, hfState
	mov temp2, flightDirection
	cpi temp1, '-'
	breq return_from_speed_change
	cpi temp1, 'H'
	breq hover_speed_change
flight_speed_change:
	cpi temp2, 'U'  
	breq return_from_speed_change
	cpi temp2, 'D'
	breq return_from_speed_change
	rjmp continue_speed_change
hover_speed_change:
	cpi temp2, 'U'
	breq continue_speed_change
	cpi temp2, 'D'                                                           '
	breq continue_speed_change
	rjmp return_from_speed_change
continue_speed_change:
	sbis pind, 0							; if pb0 pressed run inc speed
	rjmp speed_inc
	sbis pind, 1							; if pb1 pressed run desc speed
	rjmp speed_dec
	rjmp return_from_speed_change
speed_inc:
	cpi speed, 9							;if == 9m/s dont increase
	breq debounce_delay_0     
	inc speed
	rjmp debounce_delay_0
speed_dec:
	cpi speed, 0							;if == 0m/s dont decrease
	breq debounce_delay_1
	dec speed
	rjmp debounce_delay_1

; Check for debounce for button 0
debounce_delay_0:
	rcall sleep_5ms
	sbic PIND, 0		; Skip if pin is 0 (Still pressed)
	rjmp dec_count_0
	inc temp1				; Increment the delay count because button still pressed
	rjmp check_count_0
dec_count_0:
    dec temp1				; Decrement the delay count
check_count_0:
	cpi temp1, 0
    breq return_from_speed_change
	cpi temp1, 40
	breq return_from_speed_change
	rjmp debounce_delay_0
; Check for debounce for button 1
debounce_delay_1:
	rcall sleep_5ms
	sbic PIND, 1			; Skip if pin is 0 (Still pressed)
	rjmp dec_count_0
	inc temp1				; Increment the delay count because button still pressed
	rjmp check_count_1
dec_count_1:
    dec temp1				; Decrement the delay count
check_count_1:
	cpi temp1, 0
    breq return_from_speed_change
	cpi temp1, 40
	breq return_from_speed_change
	rjmp debounce_delay_1
 
.macro init_accident_location
	push temp1
	push temp2
	push temp3
	push xl
	push zl
	clr xl
	clr func_return2
	clr acci_loc_y
	clr acci_loc_x
	clr acci_loc_z
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'c'
	do_lcd_data 'i'
	do_lcd_data ':'
	do_lcd_data '('
	do_lcd_data 'x'
	do_lcd_data ','
	do_lcd_data 'y'
	do_lcd_data ')'
	do_lcd_data ':'
acci_loc_loop:
	cpi xl, 2
	breq end_acci_loc_loop
	call handle_accident_input
	cpi xl, 1
	breq skip_comma
	do_lcd_data ','
	skip_comma:
	cpi xl, 1
	brlo store_acci_x
	breq store_acci_y
store_acci_x:
	add acci_loc_x, func_return2
	rjmp reset_for_next_loop
store_acci_y:
	add acci_loc_y, func_return2
reset_for_next_loop:
	inc xl
	clc
	wait
	clr func_return2
	clr func_return
	rjmp acci_loc_loop
end_acci_loc_loop:
	z_from_x_y acci_loc_x, acci_loc_y
	mov acci_loc_z, func_return
	do_lcd_command 0x01
	;/////// DEBUG ////////
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'c'
	do_lcd_data 'i'
	do_lcd_data ':'
	do_lcd_data '('
	mov temp1, acci_loc_x
	mov temp2, acci_loc_y
	mov temp3, acci_loc_z
	send_digits_to_lcd temp1
	do_lcd_data ','
	send_digits_to_lcd temp2
	do_lcd_data ','
	send_digits_to_lcd temp3
	do_lcd_data ')'
	;/////// DEBUG ////////
	wait
	wait
	wait
	wait
	wait
	wait
	do_lcd_command 0x01
	wait
	wait
	pop xl
	pop zl
	pop temp3
	pop temp2
	pop temp1
	sei
.endmacro
 
handle_accident_input:
	push temp1
	push temp2
	push temp3
	clr temp1
	clr temp2
	clr temp3
acci_input_loop:
	wait
	get_input
	mov temp3, func_return
	cpi temp3, 0
	breq acci_input_loop
	mov temp3, func_return
	cpi temp2, 1
	brlo accident_first_digit
	breq accident_second_digit
accident_first_digit:
	cpi temp3, '2'
	brsh invalid_acci_input
	cpi temp3, '0'
	brlo invalid_acci_input
	inc temp2
	do_lcd_data_reg temp3
	cpi temp3, '1'
	brlo skip_tens
	ldi temp3, 10
	add func_return2, temp3
	skip_tens:
	rjmp acci_input_loop
	; assume that we will never get a number greater than 15 i.e., no one will ever type 16..19
accident_second_digit:
	cpi temp3, ':'
	brsh invalid_acci_input
	inc temp2
	do_lcd_data_reg temp3
	subi temp3, '0'
	add func_return2, temp3
	rjmp handle_accident_input_end
invalid_acci_input:
	flash_n_times 1
	rjmp acci_input_loop
handle_accident_input_end:
	pop temp3
	pop temp2
	pop temp1
	clr func_return
	ret

main:
	init_accident_location
	sei
	running_loop:
		get_input
		tst func_return   
		breq running_loop
		handle_input
		rjmp running_loop
