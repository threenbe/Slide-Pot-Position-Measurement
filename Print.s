; Print.s
; Raiyan Chowdhury, Timberlon Gray
; Last modification date: change this to the last modification date or look very silly
; Runs on LM4F120 or TM4C123
; EE319K lab 7 device driver for any LCD
;
; As part of Lab 7, students need to implement these LCD_OutDec and LCD_OutFix
; This driver assumes two low-level LCD functions
; ST7735_OutChar   outputs a single 8-bit ASCII character
; ST7735_OutString outputs a null-terminated string 

    IMPORT   ST7735_OutChar
    IMPORT   ST7735_OutString
    EXPORT   LCD_OutDec
    EXPORT   LCD_OutFix

    AREA    |.text|, CODE, READONLY, ALIGN=2
	PRESERVE8
    THUMB

d		EQU	0
data	EQU	4

;-----------------------LCD_OutDec-----------------------
; Output a 32-bit number in unsigned decimal format
; Input: R0 (call by value) 32-bit unsigned number
; Output: none
; Invariables: This function must not permanently modify registers R4 to R11
; Barrett Reduction: X mod Y = X - (X/Y)Y
LCD_OutDec
	PUSH {R11, LR}
	MOV R1, R0
	MOV R0, #0
	PUSH {R0}	; local variable "d"
	MOV R11, SP
	
again	; d = data % 10, we do this to get isolote digits of data to output later
	LDRB R0, [R11, #d]
	MOV R2, #10
	B mod_dec
ret	STRB R0, [R11, #d]
	PUSH {R0}	; store each digit onto stack for outputting later on
	UDIV R1, R2
	
	; Check to see if we're done getting digits from the data
	CMP R1, #0
	BNE again
out		; Output each digit by popping the digits off the stack and converting to ASCII
	POP {R0}
	ADD R0, #0x30
	BL ST7735_OutChar
	CMP SP, R11
	BEQ done
	B out
	
done
	ADD SP, #4
	POP {R11, PC}	; in place of BX LR 
	
mod_dec	; d = data % 10
	MOV R3, R1
	UDIV R3, R2
	MUL R3, R2
	SUB R0, R1, R3
	B ret
	
      
;* * * * * * * * End of LCD_OutDec * * * * * * * *

; -----------------------LCD _OutFix----------------------
; Output characters to LCD display in fixed-point format
; unsigned decimal, resolution 0.001, range 0.000 to 9.999
; Inputs:  R0 is an unsigned 32-bit number
; Outputs: none
; E.g., R0=0,    then output "0.000 "
;       R0=3,    then output "0.003 "
;       R0=89,   then output "0.089 "
;       R0=123,  then output "0.123 "
;       R0=9999, then output "9.999 "
;       R0>9999, then output "*.*** "
; Invariables: This function must not permanently modify registers R4 to R11
LCD_OutFix
	PUSH {R11, LR}
	MOV R1, R0
	MOV R0, #0
	PUSH {R0, R1}
	
	MOV R2, #9999
	CMP R1, R2
	BHI stars

	MOV	R2, #1000	;Find/output 1000s place, subtract from output data
	UDIV R0, R1, R2	; d = data/1000
	STR R0, [SP, #d]
	MUL	R3, R0, R2
	SUB	R1, R3	; data = data % 1000
	STR R1, [SP, #data]
	ADD	R0, #0x30
	BL	ST7735_OutChar

	MOV	R0, #0x2E	;Decimal point
	BL	ST7735_OutChar	
	
	MOV	R2, #100	;Find/output 100s place, subtract from output data
	LDR R0, [SP, #d]
	LDR R1, [SP, #data]
	UDIV R0, R1, R2	; d = data/100
	STR R0, [SP, #d]
	MUL	R3, R0, R2
	SUB	R1, R3	; data = data % 100
	STR R1, [SP, #data]
	ADD	R0, #0x30
	BL	ST7735_OutChar
	
	MOV	R2, #10	;Find/output 10s place, subtract from output data
	LDR R0, [SP, #d]
	LDR R1, [SP, #data]
	UDIV R0, R1, R2	; d = data/10
	STR R0, [SP, #d]
	MUL	R3, R0, R2
	SUB	R1, R3	; data = data % 10
	STR R1, [SP, #data]
	ADD	R0, #0x30
	BL	ST7735_OutChar
	
	LDR R1, [SP, #data]
	MOV R0, R1	;Output 1s place
	ADD	R0, #0x30
	BL	ST7735_OutChar
finished
	ADD SP, #8
	POP {R11, PC}	; in place of BX LR

stars
	MOV R0, #0x2A
	BL ST7735_OutChar
	MOV R0, #0x2E
	BL ST7735_OutChar
	MOV R0, #0x2A
	BL ST7735_OutChar
	MOV R0, #0x2A
	BL ST7735_OutChar
	MOV R0, #0x2A
	BL ST7735_OutChar
	B finished
 
     ALIGN
;* * * * * * * * End of LCD_OutFix * * * * * * * *

     ALIGN                           ; make sure the end of this section is aligned
     END                             ; end of file
