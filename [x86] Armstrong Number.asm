; Author: Mark Edward M. Gonzales, Section S15

; An "Armstrong" number is define as "m-digit positive number equal to sum of the m-th
; powers of their digits."
; 
; For Example: Number 1634 is an Armstrong number since 1^4+6^4+3^4+4^4 = 1634
;
; ----Instruction----
;
; Write a working x86 assembly program that accepts as input a positive integer 
; and determine if the number is an "Armstrong" number.
;
; Input: prompt user for an input.  Input should be a positive integer.  
; 
; Error checking: (1) null input (2) invalid input (3) not within range. 
;                 If error exists, output an appropriate error message and input again.
;
; Process: Check if the input is an Armstrong number
;
; Output: List the m-th power of the digits, the sum and whether it is an Armstrong number.
;
; Prompt the user whether the program will be executed again.

%include "io.inc"

section .data
; =================================================================================
; Variables for storing user inputs (as strings)
; - Store a maximum of 80 characters (excluding newline and null terminator)
; =================================================================================
user_input times 82 db 0
continue_input times 82 db 0

; =================================================================================
; Variables related to the number entered by the user and counters for its digits
; =================================================================================

; Number entered by the user
; - The default for integer is double word.
number dd 0x00000000

; Number of digits in the number entered by the user
; - Maximum number of digits for a 32-bit unsigned integer is 10, which fits in a byte.
num_digits db 0x00

; Number of remaining digits for processing
; - This will never exceed num_digits; thus, it also fits in a byte.
num_rem_digits db 0x00

; =================================================================================
; Reset to 0x00 if summing the m-th powers does not result in an overflow;
; set to 0x01, otherwise. Therefore, it fits in a byte.
; =================================================================================
is_sum_overflow db 0x00

; =================================================================================
; Prompts and messages
; =================================================================================
input_prompt db "Input Number: ", 0
continue_prompt db "Do you want to continue (Y/N)? ", 0

mth_power_result db "m-th power of each digits: ", 0
sum_result db "Sum of the m-th power digits: ", 0
armstrong_result db "Armstrong Number: ", 0

error_null db "Error: Null input", 0
error_invalid db "Error: Invalid input", 0
error_invalid_yn db "Error: Invalid input (Y/N only)", 0
error_out_of_range db "Error: Not within range (exceeds max 32-bit unsigned integer, 4294967295)", 0


section .text
global CMAIN
CMAIN:
    ;write your code here
    
; =================================================================================
; Prompt the user to enter a number and check whether the input is null.
; =================================================================================
input_num:
    ; Read a maximum of 80 characters (excluding newline).
    PRINT_STRING input_prompt
    GET_STRING user_input, 81       ; Take enter key into account.

    LEA ESI, [user_input]

    ; A character is 1 byte.
    MOV BL, [ESI]
    
    ; Since the input is from the DOS/CLI prompt, a string is considered null
    ; if the user presses the enter key without typing anything. Hence, this code
    ; checks if the first character of the string is the newline (ASCII: 0x0A).
    CMP BL, 0x0A
    JE null_input
    
    ; Technically, a null string is a string containing only the null terminator.
    ; Although the input is from the DOS/CLI prompt (necessitating the enter key 
    ; to be pressed), this code still checks if the first character of the string 
    ; is the null terminator for additional insurance.
    CMP BL, 0x00
    JE null_input

; =================================================================================
; Check whether the user input is invalid, that is, the user input contains a
; non-numerical character. Consequently, this also catches the case when the user
; input is negative (due to the non-numerical negative sign) --- which is also an 
; invalid case since Armstrong numbers should be positive integers.

; Note that checking whether the user input is 0 (which is also an invalid case)
; is deferred to the latter part of the program.
; =================================================================================
check_invalid:
    ; Only positive integers are allowed. Therefore, a valid input should contain 
    ; only characters between '0' and '9', inclusive.
    CMP BL, '0'
    JL invalid_input
    
    CMP BL, '9'
    JG invalid_input
    
    ; Iterate through every character.
    INC ESI
    MOV BL, [ESI]

    ; Reaching the newline character or null terminator without reading a non-numerical 
    ; character indicates that the input is a nonnegative integer.    
    CMP BL, 0x0A
    JE back_to_msd

    CMP BL, 0x00
    JE back_to_msd
    
    JMP check_invalid

; =================================================================================
; If the user input is a nonnegative integer, re-examine the number again starting 
; from the most significant digit in order to convert the string input to an integer 
; and, thus, check for overflow.
;
; The rationale for separating the invalid and overflow checks into two iterations
; is to handle cases such as 999999999999abc. If both checks were to be done in one
; iteration, this would be registered as overflow since 9999999999 already exceeds
; the maximum 32-bit unsigned integer. However, the correct error is invalid input
; since the last three characters are non-numerical. 
; =================================================================================
back_to_msd:
    ; Initialize the values of these registers to 0 since they will be used later on.
    MOV EAX, 0x00000000             ; Stores the integer conversion of the user input
    MOV EBX, 0x00000000             ; BL stores the integer conversion of each character
    MOV ECX, 0x00000000             ; Counter for the number of digits
    
    ; This will serve as the multiplier in converting the string input to an integer.
    ; Hence, it is set to 10 (hex: 0x0000000A). The MUL instruction for unsigned
    ; multiplication does not accept an immediate operand.
    MOV EDI, 0x0000000A

    ; Return to the most significant digit (that is, the first character).
    LEA ESI, [user_input]
    MOV BL, [ESI]
   
char_to_digit:
    ; Convert the character to an integer (for example, '0' to 0). This can be done by
    ; performing '0' - '0' = 0. Analogously, the integer conversion for any numerical
    ; character is x - '0', where x is the ASCII code for that character.
    SUB BL, '0'
    
    ; Replace the character with its integer conversion. For example, if user_input is 
    ; '9', '8', '6', '\0', then, after the first iteration, it becomes 9, '8', '6', '\0'
    ; (with emphasis on the conversion of '9' to 9). This is an optimization done since
    ; the m-th power of each digit will be computed in the latter part of the program.
    MOV [ESI], BL
    
    ; Use MUL to perform unsigned multiplication: EAX * 10. This multiplication "makes
    ; room" for the next digit by pushing all the digits one place value higher and
    ; setting the least significant digit to 0.
    MUL EDI
    
    ; Check if this multiplication signals that the user input is out of range using the 
    ; carry flag (can also be done via the overflow flag).
    JC out_of_range
    
    ; Add the value of BL to this product. However, since register EAX is 32-bit,
    ; EBX is considered (this is also the reason for initializing EBX to 0 beforehand,
    ; that is, to prevent garbage values). 
    
    ; At the end of this operation, EAX now stores the integer conversion of the string 
    ; input considering all the characters (digits) that have been read so far.
    ADD EAX, EBX
    
    ; Check if this addition signals that the user input is out of range using the
    ; carry flag (a set carry flag indicates overflow in unsigned addition).
    JC out_of_range
    
    ; Iterate through every character, and increase the counter for the number of digits.
    ; Although the number of digits can fit inside CL, the LOOP instruction to be used
    ; in the exponentiation depends on ECX (this is also the reason for initializing ECX 
    ; to 0 beforehand, that is, to prevent garbage values).
    INC ECX
    INC ESI
    MOV BL, [ESI]
    
    ; Reaching the newline character or null terminator without reading a non-numerical 
    ; character indicates that the input is a nonnegative integer within the range
    ; of a 32-bit unsigned integer.  
    CMP BL, 0x0A
    JE prepare_armstrong
    
    CMP BL, 0x00
    JE prepare_armstrong

    JMP char_to_digit

; =================================================================================
; When an error is trapped, ask the user if they are going to continue.
; =================================================================================   
null_input:
    PRINT_STRING error_null
    JMP continue_ques
    
invalid_input:
    PRINT_STRING error_invalid
    JMP continue_ques
    
out_of_range:
    PRINT_STRING error_out_of_range
    ; No need for JMP since it is the next instruction.
    
continue_ques:
    ; Read a maximum of 80 characters (excluding newline).
    NEWLINE
    PRINT_STRING continue_prompt
    GET_STRING continue_input, 81       ; Take enter key into account.
    
    ; Since the input is from the DOS/CLI prompt, a string is considered null
    ; if the user presses the enter key without typing anything. Hence, this code
    ; checks if the first character of the string is the newline (ASCII: 0x0A). 
    CMP byte [continue_input], 0x0A
    JE null_input
    
    ; Technically, a null string is a string containing only the null terminator.
    ; Although the input is from the DOS/CLI prompt (necessitating the enter key 
    ; to be pressed), this code still checks if the first character of the string 
    ; is the null terminator for additional insurance.
    CMP byte [continue_input], 0x00
    JE null_input
    
    ; A necessary but not sufficient condition for the user's input to be valid
    ; is for it to be a single-character string.
    
    ; Since the input is from the DOS/CLI prompt, having the newline as the second
    ; character indicates that the user entered only a single character before pressing
    ; the enter key. Hence, proceed to checking whether this character is 'Y', 'N', or 
    ; an invalid input.
    CMP byte [continue_input + 1], 0x0A
    JE continue_quest_cont
    
    ; Technically, a single-character string is a character followed by the null
    ; terminator. Although the input is from the DOS/CLI prompt (necessitating the
    ; enter key to be pressed), this code still checks if the second character is the
    ; null terminator for additional insurance, especially when input redirection
    ; is utilized (instead of typing directly on the DOS/CLI prompt).  
    CMP byte [continue_input + 1], 0x00
    JE continue_quest_cont
    
    JMP invalid_input_yn

; =================================================================================
; Check if the single character entered by the user is 'Y', 'N', or an invalid input.
; =================================================================================       
continue_quest_cont:
    ; Prompt the user to enter another number if they give an affirmative response ('Y').
    CMP byte [continue_input], 'Y'
    JE input_num
    
    ; Terminate the program if the user gives a negative response ('N').
    CMP byte [continue_input], 'N'
    JE program_end
    
    ; If the user entered a character other than 'Y' and 'N' (case-sensitive), proceed 
    ; to error trapping and re-prompt the user until a valid response is entered.
    ; No need for JMP since it is the next instruction.

; =================================================================================
; Perform error trapping for the continue (Y/N) question as well.
; =================================================================================           
invalid_input_yn:
    PRINT_STRING error_invalid_yn
    JMP continue_ques
 
; =================================================================================
; Prepare for the actual checking as to whether the number is an Armstrong number
; or not. To reiterate, at this point, EAX stores the integer conversion of the 
; user input. 

; Note that this also completes the checking for invalid input since this traps
; the case when the user enters a value equal to 0.
; ================================================================================= 
prepare_armstrong:
    ; Since Armstrong numbers have to be positive, 0 is considered an invalid input.
    CMP EAX, 0x00000000
    JE invalid_input

    ; Transfer the integer conversion of the user input (henceforth referred to as
    ; simply the number, unless otherwise implied by the context) to a variable.
    MOV [number], EAX
    
    ; Transfer the number of digits to two variables. It suffices for the source
    ; to be CL (instead of the entire ECX) since the maximum number of digits for 
    ; a 32-bit unsigned integer is 10, which fits in a byte.
    MOV [num_digits], CL
    MOV [num_rem_digits], CL

    ; Use EBX to store the sum of the m-th powers of the digits.
    MOV EBX, 0x00000000
    
    ; Initially, assume that there is no overflow in the sum of the m-th powers.
    MOV byte [is_sum_overflow], 0x00
    
    ; Display the message for the sum of the m-th powers.
    PRINT_STRING mth_power_result
    
    LEA ESI, [user_input]
    
    ; AL will be used to temporarily each digit. Digits are between 0 and 9, inclusive;
    ; thus, they fit in a byte.
    MOV EAX, 0x00000000
    MOV AL, [ESI]    

; =================================================================================
; Compute the sum of the m-th power of each digit, where m is the number of digits.
; ================================================================================= 
check_armstrong:
    ; Since exponentiation requires repeated unsigned multiplication and 32-bit
    ; registers are used to maximize capacity in handling large m-th powers, the digit 
    ; in AL is transferred to the 32-bit EDI. Since the source and destination need 
    ; to have matching sizes, EAX is treated as the source (this is also the reason 
    ; for initializing it to 0 beforehand, that is, to prevent garbage values).
    MOV EDI, EAX
    
    ; Since the unsigned multiplication instruction uses register EAX, it will now
    ; be used to store the m-th power of each digit (justifying the register transfer 
    ; in the previous code). Set it to 1 in preparation for exponentiation.
    MOV EAX, 0x00000001 
    
exponent:
    ; Perform repeated multiplication, with the exponent equal to the number of digits. 
    ; Use the LOOP instruction since ECX contains the number of digits.
    MUL EDI
    LOOP exponent    
    
    ; The LOOP instruction decrements ECX all the way down to 0. Its previous value is 
    ; restored using the variable for the number of digits.
    MOV CL, [num_digits]
    
    ; The m-th power of the pertinent digit is now stored in EAX, and the running sum
    ; of these m-th powers is stored in EBX.
    ADD EBX, EAX
    
    ; Use the carry flag to check if the running sum of the m-th powers exceeds the 
    ; maximum value of a 32-bit unsigned integer.
    JC sum_overflow
    
    ; If there is no overflow, proceed "normally" to the next digit.
    
exponent_cont:
    ; Display the m-th power of the digit as an unsigned decimal.
    PRINT_UDEC 4, EAX 
    
    ; Reset EAX back to 0 before proceeding to the next digit.
    MOV EAX, 0x00000000
    INC ESI
    MOV AL, [ESI]
    
    ; Update the remaining number of digits. If there are no digits left,
    ; the sum of the m-th powers can already be displayed. Otherwise, a comma 
    ; is displayed to separate the m-th powers.
    DEC byte [num_rem_digits]
    CMP byte [num_rem_digits], 0x00
    JE display_result
    
    PRINT_CHAR ','
    
    JMP check_armstrong

; =================================================================================
; If the sum of the m-th powers exceeds the maximum value of a 32-bit unsigned integer,
; set the pertinent variable to 1 before proceeding to the next digit. The intention
; is to mark that an overflow has occurred but still proceed to compute and display 
; the m-th powers of the remaining digits.

; Note that, while it is imperative to check if the sum of the m-th powers causes
; an overflow, this check is not needed for the individual m-th powers. The maximum
; number of digits of a 32-bit unsigned integer is 10; therefore, the maximum m-th
; power of a digit is 9^10 = 3486784401, which is less than 4294967295 = 2^32 - 1.
; =================================================================================         
sum_overflow:
    MOV byte [is_sum_overflow], 0x01
    JMP exponent_cont

; =================================================================================
; Display the sum of the m-th powers and the results of the Armstrong number checking.
; ================================================================================= 
display_result:
    ; Display the message for the sum of the m-th powers of the digits.
    NEWLINE
    PRINT_STRING sum_result
    
    ; Trap the error if the sum of the m-th powers exceeds the maximum value 
    ; of a 32-bit unsigned integer.
    CMP byte [is_sum_overflow], 0x01
    JE display_sum_overflow    
    
    ; To reiterate, EBX stores the sum of the m-th powers of the digits.
    PRINT_UDEC 4, EBX

    ; Display the message for the result of the Armstrong number checking.
    NEWLINE
    PRINT_STRING armstrong_result
    
    ; If the number is equal to the sum of the m-th powers of its digits, then 
    ; it is an Armstrong number. Otherwise, it is not an Armstrong number.
    CMP [number], EBX
    JE confirmed_armstrong
    
    JMP confirmed_not_armstrong
    
confirmed_armstrong:
    PRINT_STRING "Yes"
    
    ; Ask the user if they are going to continue.
    JMP continue_ques

; =================================================================================
; If the sum of the m-th powers of the digits causes an overflow, then it is certain
; that the number is not an Armstrong number since the sum already exceeds the value
; of the number itself.
; =================================================================================     
display_sum_overflow:
    PRINT_STRING error_out_of_range
    NEWLINE
    PRINT_STRING armstrong_result
    
    ; No need for JMP since it is already the next instruction.
    
confirmed_not_armstrong:
    PRINT_STRING "No"
    
    ; Ask the user if they are going to continue.
    JMP continue_ques
          
program_end:
    xor eax, eax
    ret