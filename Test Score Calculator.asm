;********************************************************************
; Program: Test Score Calculator
; Description: Calculates Min, Max, Average of 5 scores and assigns
;              letter grades.
;********************************************************************

.ORIG x3000

;**********************
; MAIN INITIALIZATION  
;**********************

LD R6, STACK_PTR       ; Initialize stack pointer
LEA R4, SCORE_ARRAY    ; R4 as array pointer
AND R5, R5, #0
ADD R5, R5, #5         ; Loop counter for 5 scores

;*************
; INPUT LOOP
;*************

INPUT_LOOP
    LEA R0, PROMPT
    PUTS                   ; Print to console
    
    JSR READ_NUM           ; Call subroutine for multi-digit number
    
    STR R1, R4, #0         ; Store result in array
    ADD R4, R4, #1         ; Increment pointer
    ADD R5, R5, #-1        ; Decrement counter
    BRp INPUT_LOOP         ; Conditional branch for 5 iterations

;**************************
; CALCULATE MIN, MAX, SUM
;**************************

LEA R4, SCORE_ARRAY
LDR R1, R4, #0         ; Initialize 'min' (R1)
LDR R2, R4, #0         ; Initialize 'max' (R2)
AND R3, R3, #0         ; Initialize 'sum' (R3)
AND R5, R5, #0
ADD R5, R5, #5         ; Reset loop counter to 5

CALC_LOOP
    LDR R0, R4, #0         ; Load current array value
    ADD R3, R3, R0         ; Add current score to sum

    ; Check if max
    NOT R7, R2
    ADD R7, R7, #1         ; 2s complement of current max
    ADD R7, R0, R7         ; Compare current score to max
    BRnz SKIP_NEW_MAX      ; Skip if negative or zero
    ADD R2, R0, #0         ; Else, update max
    SKIP_NEW_MAX

    ; Check if min
    NOT R7, R1
    ADD R7, R7, #1         ; 2s complement of current min
    ADD R7, R0, R7         ; Compare current score to min
    BRzp SKIP_NEW_MIN      ; Skip if positive or zero
    ADD R1, R0, #0         ; Else, update min
    SKIP_NEW_MIN

    ADD R4, R4, #1         ; Increment array pointer
    ADD R5, R5, #-1        ; Decrement loop counter
    BRp CALC_LOOP

; Store calculated values
ST R1, MIN_SCORE
ST R2, MAX_SCORE
ST R3, SUM_SCORE

;********************
; CALCULATE AVERAGE
;********************

LD R3, SUM_SCORE
AND R4, R4, #0         ; R4 = Average
ADD R5, R3, #0         ; R5 = Remainder

AVG_LOOP               ; Divide
    ADD R5, R5, #-5
    BRn END_AVG        ; Break if remainder is negative
    ADD R4, R4, #1     ; Increment quotient
    BRnzp AVG_LOOP     ; Unconditional branch
END_AVG
    ST R4, AVG_SCORE

;*****************
; OUTPUT RESULTS
;*****************

LEA R0, MSG_MIN
PUTS
LD R1, MIN_SCORE
JSR PRINT_NUM
JSR PRINT_GRADE

LEA R0, MSG_MAX
PUTS
LD R1, MAX_SCORE
JSR PRINT_NUM
JSR PRINT_GRADE

LEA R0, MSG_AVG
PUTS
LD R1, AVG_SCORE
JSR PRINT_NUM
JSR PRINT_GRADE

HALT

;*********************************************
; SUBROUTINE: READ_NUM
; - Convert multi-digit ASCII string to int.
;*********************************************

READ_NUM
    ST R7, SAVED_R7_READ   ; Save register
    ST R0, SAVED_R0_READ
    ST R2, SAVED_R2_READ
    ST R3, SAVED_R3_READ

    AND R1, R1, #0         ; Initialize R1

READ_CHAR_LOOP
    GETC                   ; Read character
    OUT                    ; Output character

    ; Check for enter/return
    ADD R2, R0, #-10
    BRz READ_DONE
    ADD R2, R0, #-13
    BRz READ_DONE

    ; Convert ASCII to integer
    LD R2, ASCII_OFFSET_NEG
    ADD R0, R0, R2         ; Subtract 48

    ; Multiply total by 10
    ADD R2, R1, #0
    AND R3, R3, #0
    ADD R3, R3, #9
    
MUL_LOOP
    ADD R1, R1, R2
    ADD R3, R3, #-1
    BRp MUL_LOOP

    ADD R1, R1, R0         ; Add new digit to total
    BRnzp READ_CHAR_LOOP

READ_DONE
    LD R7, SAVED_R7_READ   ; Restore registers
    LD R0, SAVED_R0_READ
    LD R2, SAVED_R2_READ
    LD R3, SAVED_R3_READ
    RET

SAVED_R7_READ .BLKW 1
SAVED_R0_READ .BLKW 1
SAVED_R2_READ .BLKW 1
SAVED_R3_READ .BLKW 1
ASCII_OFFSET_NEG .FILL #-48

;*************************************************************
; SUBROUTINE: PRINT_NUM 
; - Integer in R1 converted to multi-digit ASCII and prints.
;*************************************************************

PRINT_NUM
    ST R7, SAVED_R7_PRINT
    ST R0, SAVED_R0_PRINT
    ST R1, SAVED_R1_PRINT
    ST R2, SAVED_R2_PRINT
    ST R3, SAVED_R3_PRINT
    ST R4, SAVED_R4_PRINT

    ADD R1, R1, #0
    BRz PRINT_ZERO_CASE

    AND R2, R2, #0         ; Digit counter

EXTRACT_DIGIT_LOOP
    AND R3, R3, #0         ; Quotient
    ADD R4, R1, #0         ; Starting current value is remainder
    
SUB_TEN_LOOP
    ADD R4, R4, #-10
    BRn END_SUB_TEN
    ADD R3, R3, #1
    BRnzp SUB_TEN_LOOP
    
END_SUB_TEN
    ADD R4, R4, #10        ; Make remainder positive again

    ; Push extracted digit to stack 
    ADD R0, R4, #0         
    JSR PUSH               
    ADD R2, R2, #1         ; Increment digit count

    ADD R1, R3, #0         ; Update value to quotient
    BRp EXTRACT_DIGIT_LOOP

OUTPUT_DIGITS
    ; Pop digit from stack to output in correct order 
    JSR POP                
    LD R3, ASCII_OFFSET_POS
    ADD R0, R0, R3         ; Convert int back to ASCII 
    OUT
    ADD R2, R2, #-1
    BRp OUTPUT_DIGITS
    BRnzp PRINT_END

PRINT_ZERO_CASE
    LD R0, ASCII_ZERO_CHAR
    OUT

PRINT_END
    LD R7, SAVED_R7_PRINT
    LD R0, SAVED_R0_PRINT
    LD R1, SAVED_R1_PRINT
    LD R2, SAVED_R2_PRINT
    LD R3, SAVED_R3_PRINT
    LD R4, SAVED_R4_PRINT
    RET

SAVED_R7_PRINT .BLKW 1
SAVED_R0_PRINT .BLKW 1
SAVED_R1_PRINT .BLKW 1
SAVED_R2_PRINT .BLKW 1
SAVED_R3_PRINT .BLKW 1
SAVED_R4_PRINT .BLKW 1
ASCII_OFFSET_POS .FILL #48
ASCII_ZERO_CHAR .FILL x30

;*****************************************************************
; SUBROUTINES: PUSH AND POP 
; - Stack memory is managed manually. Stack grows towards x0000.
;*****************************************************************

PUSH
    ADD R6, R6, #-1        ; Decrement stack pointer
    STR R0, R6, #0         ; Store R0 at top of stack
    RET

POP
    LDR R0, R6, #0         ; Load top of stack into R0
    ADD R6, R6, #1         ; Increment stack pointer
    RET

;************************************************************************
; SUBROUTINE: PRINT_GRADE 
; - Determines letter grade from numeric score in R1 and prints result.
;************************************************************************

PRINT_GRADE
    ST R7, SAVED_R7_GRADE
    ST R0, SAVED_R0_GRADE
    ST R2, SAVED_R2_GRADE

    LEA R0, GRADE_PREFIX
    PUTS

    LD R2, MINUS_90
    ADD R0, R1, R2
    BRzp IS_A_GRADE

    LD R2, MINUS_80
    ADD R0, R1, R2
    BRzp IS_B_GRADE

    LD R2, MINUS_70
    ADD R0, R1, R2
    BRzp IS_C_GRADE

    LD R2, MINUS_60
    ADD R0, R1, R2
    BRzp IS_D_GRADE

    ; Default: F Grade
    LD R0, CHAR_F_VAL
    OUT
    BRnzp END_GRADE

IS_A_GRADE
    LD R0, CHAR_A_VAL
    OUT
    BRnzp END_GRADE
    
IS_B_GRADE
    LD R0, CHAR_B_VAL
    OUT
    BRnzp END_GRADE
    
IS_C_GRADE
    LD R0, CHAR_C_VAL
    OUT
    BRnzp END_GRADE
    
IS_D_GRADE
    LD R0, CHAR_D_VAL
    OUT

END_GRADE
    LEA R0, NEWLINE_STR
    PUTS

    LD R7, SAVED_R7_GRADE
    LD R0, SAVED_R0_GRADE
    LD R2, SAVED_R2_GRADE
    RET

SAVED_R7_GRADE .BLKW 1
SAVED_R0_GRADE .BLKW 1
SAVED_R2_GRADE .BLKW 1

MINUS_90 .FILL #-90
MINUS_80 .FILL #-80
MINUS_70 .FILL #-70
MINUS_60 .FILL #-60

CHAR_A_VAL .FILL x41
CHAR_B_VAL .FILL x42
CHAR_C_VAL .FILL x43
CHAR_D_VAL .FILL x44
CHAR_F_VAL .FILL x46

GRADE_PREFIX .STRINGZ " (Grade: "
NEWLINE_STR  .STRINGZ ")\n"

;********************************
; MEMORY ALLOCATION & VARIABLES
;********************************

STACK_PTR   .FILL x4000    ; Stack base address 
SCORE_ARRAY .BLKW 5        ; Array to hold exactly 5 inputs
MIN_SCORE   .BLKW 1
MAX_SCORE   .BLKW 1
SUM_SCORE   .BLKW 1
AVG_SCORE   .BLKW 1

PROMPT      .STRINGZ "Enter test score (Press Enter): "
MSG_MIN     .STRINGZ "Minimum Score: "
MSG_MAX     .STRINGZ "Maximum Score: "
MSG_AVG     .STRINGZ "Average Score: "

.END
