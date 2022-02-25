; Author: Mark Edward M. Gonzales, Section S15

; Normalization is a common technique in data science that aims to change values 
; of a given dataset to use a common scale, without losing any information. 
; The equation for normalizing values from 0 to 1.0 is given below:

; x_normalized = (x - min(x)) / (max(x) - min(x))

; INPUT:
; Prompt the user to enter, one by one, three values (value1, value2, value3). 
; See the given sample runs. Error checking includes no character input values 
; and all the values should be unique.

; OUTPUT:
; Display the minimum, maximum and the normalized output on the screen. Each 
; normalized output having a format of (quotient, remainder) then separated 
; by a semi-colon and space. 

; Screen should be cleared for each run of the program.


; =================================================================================
; x86-to-C interface
; - printf is used for output
; - gets is used for input
; - system is used for clearing the the screen
; =================================================================================
global _main
extern _printf, _gets, _system


section .data
; =================================================================================
; Input prompts, display messages, and error messages
; - 10 is the ASCII value for line feed ('\n')
; - 0 is the ASCII value for the null terminator ('\0')
; =================================================================================
input_prompt1 db "Enter value 1:", 10, 0
input_prompt2 db "Enter value 2:", 10, 0
input_prompt3 db "Enter value 3:", 10, 0

continue_prompt db "Do you want to continue? (Y/N/yes/no)", 10, 0

message_min db "Minimum:", 10, 0
message_max db "Maximum:", 10, 0
message_norm db "Normalized output:", 10, 0

error_null db "Error: Null input", 10, 0
error_invalid_char db "Error: Character input values are not allowed", 10, 0
error_invalid_unique db "Error: Please enter unique values", 10, 0

error_invalid_input db "Error: Y, N, yes, or no only (not case sensitive)", 10, 0

; =================================================================================
; Variables related to the C display flags, line feed, and clear screen
; - %d is the display flag for signed integer
; - %u is the display flag for unsigned integer
; - 10 is the ASCII value for line feed ('\n')
; - cls is the system method parameter for clearing the screen
; =================================================================================
int_flag db "%d", 0
norm_format_semicolon db "%d,%u; ", 0
norm_format_no_semicolon db "%d,%u", 10, 0

newline db 10, 0
cls_str db "cls", 0

; =================================================================================
; Variables for storing user inputs (as strings)
; - Store a maximum of 80 characters (excluding newline and null terminator)
; =================================================================================
value_str1 times 82 db 0
value_str2 times 82 db 0
value_str3 times 82 db 0

continue_input times 82 db 0

; =================================================================================
; Variables for storing user inputs (as integers)
; - The default for integer is double word.
; =================================================================================
value1 dd 0x00000000
value2 dd 0x00000000
value3 dd 0x00000000


section .text
_main:
    ;write your code here    
; =================================================================================
; Clear the screen for each run of the program.
; =================================================================================
start_program:
    PUSH cls_str
    CALL _system
    ADD ESP, 4
    
    ; This will serve as the multiplier in converting the string input to an integer.
    ; Hence, it is set to 10 (hex: 0x0000000A). The MUL instruction for unsigned
    ; multiplication does not accept an immediate operand.
    MOV EDI, 0x0000000A

; =================================================================================
; Prompt the user to enter value 1, perform error trapping, and convert it
; to an integer if it is valid.
; =================================================================================    
enter_value1:
    ; Use EBX to keep track of the sign of value 1.
    ; Specifically, its least significant bit is set to 1 if value 1 is negative
    ; and reset to 0 otherwise. Initially, assume that value 1 is nonnegative.
    MOV EBX, 0x00000000

    ; printf("Enter value 1:")
    PUSH input_prompt1
    CALL _printf
    ADD ESP, 4
    
    ; Use gets in order to accept string input with whitespaces.
    ; gets(value_str1)
    PUSH value_str1
    CALL _gets
    ADD ESP, 4
    
    ; Reset the following registers since they will be used in succeeding computations.
    ; Note that this reset is necessary since EAX and ECX (along with EDX) are caller-
    ; saved registers, i.e., their values are modified by calling C functions.
    MOV EAX, 0x00000000
    MOV ECX, 0x00000000
        
    ; Perform null input trapping for value 1.
    ; A character is 1 byte.
    LEA ESI, [value_str1]    
    MOV CL, [ESI]

    ; Since the input is from the DOS/CLI prompt, a string is considered null
    ; if the user presses the enter key without typing anything. Hence, this code
    ; checks if the first character of the string is the newline (ASCII: 0x0A).
    CMP CL, 0x0A
    JE null_input_value1
    
    ; Technically, a null string is a string containing only the null terminator.
    ; Although the input is from the DOS/CLI prompt (necessitating the enter key 
    ; to be pressed), this code still checks if the first character of the string 
    ; is the null terminator for additional insurance.
    CMP CL, 0x00
    JE null_input_value1
    
    ; Check the sign of value 1.
    CMP CL, '-'   
    JE neg_value1
    
    ; If value 1 is nonnegative, proceed to check each character.
    JMP check_invalid_value1

; If value 1 is negative, set the least significant bit of EBX to 1. In this regard,
; it is sufficient to consider only register BL.
neg_value1:
    MOV BL, 0x01
    ; Proceed to the next character. The only admissible non-numerical character
    ; is the negative sign ('-').
    INC ESI

; Check whether value 1 is invalid, that is, it contains a non-numerical character.     
check_invalid_value1:
    ; If the input has an initial negative sign, CL now stores the second
    ; character of the string (following the previous INC ESI instruction). 
    ; Otherwise, CL contains the first character of the string.
    MOV CL, [ESI]
    
    ; Reaching the newline character or null terminator without reading a 
    ; non-numerical character indicates that the input is a valid integer.    
    CMP CL, 0x0A
    JE convert_value1

    CMP CL, 0x00
    JE convert_value1
    
    ; A valid input should contain only characters between '0' and '9', inclusive.
    CMP CL, '0'
    JL invalid_char_value1
    
    CMP CL, '9'
    JG invalid_char_value1
    
    ; Proceed to the next character.
    INC ESI
    JMP check_invalid_value1

; Prepare for the conversion of value 1 to an integer. 
convert_value1:
    ; Return to the most significant digit (i.e., the first character).
    LEA ESI, [value_str1]

    ; Note that the least significant bit of EBX is used to keep track of the sign 
    ; of value 1. Therefore, it suffices to consider byte 0 of BX.
    BT BX, 0x00
    JC skip_neg_sign_value1
    
    ; If value 1 is nonnegative, convert it to an integer directly.
    JMP to_int_value1

; If value 1 is negative, skip the negative sign before integer conversion.        
skip_neg_sign_value1:
    INC ESI
    
to_int_value1:
    MOV CL, [ESI]
    
    ; Conversion is considered finished when either the newline character or the null 
    ; terminator is reached.
    CMP CL, 0x0A
    JE convert_neg_value1
    
    CMP CL, 0x00
    JE convert_neg_value1
    
    ; Convert the character to an integer (for example, '0' to 0). This can be done by
    ; performing '0' - '0' = 0. Analogously, the integer conversion for any numerical
    ; character is x - '0', where x is the ASCII code for that character.
    SUB CL, '0'
       
    ; Use MUL to perform unsigned multiplication: EAX * 10. This multiplication "makes
    ; room" for the next digit by pushing all the digits one place value higher and
    ; setting the least significant digit to 0.
    MUL EDI
    
    ; At the end of this operation, EAX now stores the integer conversion of the string 
    ; input considering all the characters (digits) that have been read so far.
    
    ; Note that ECX is considered in order to match register sizes and perform 32-bit
    ; addition. This also provides the rationale for resetting the entire ECX at the 
    ; start of the routine.
    ADD EAX, ECX
    
    ; Proceed to the next character (digit).
    INC ESI
    JMP to_int_value1

; If value 1 is negative, take the negative of the current integer conversion.           
convert_neg_value1:
    BT BX, 0x00
    JC affix_neg_sign_value1
    
    ; If value 1 is nonnegative, then proceed directly to saving the integer conversion.
    JMP save_value1
    
affix_neg_sign_value1:
    ; The negative is obtained by taking the two's complement.
    NEG EAX
    
    ; No need for JMP since it is the next instruction.
    
save_value1:
    ; Store the integer conversion (in register EAX) to the dedicated memory location.
    MOV [value1], EAX
    
    ; Proceed to entering value 2.
    JMP enter_value2

; Trap errors related to a null input.   
null_input_value1:
    ; printf("Error: Null input")
    PUSH error_null
    CALL _printf
    ADD ESP, 4
    
    ; Prompt the user to enter another value.
    JMP enter_value1

; Trap errors related to an input with non-numerical characters.
invalid_char_value1:
    ; printf("Error: Character input values are not allowed")
    PUSH error_invalid_char
    CALL _printf
    ADD ESP, 4
    
    ; Prompt the user to enter another value.
    JMP enter_value1
   
; =================================================================================
; Prompt the user to enter value 2, perform error trapping, and convert it
; to an integer if it is valid.

; The logic of this routine is analogous to that for value 2. Therefore, in the
; interest of brevity, the documentation for analogous instructions is omitted.
; =================================================================================   
enter_value2:   
    MOV EBX, 0x00000000

    PUSH input_prompt2
    CALL _printf
    ADD ESP, 4
    
    PUSH value_str2
    CALL _gets
    ADD ESP, 4
    
    MOV EAX, 0x00000000
    MOV ECX, 0x00000000
    
    LEA ESI, [value_str2]    
    MOV CL, [ESI]
    
    CMP CL, 0x0A
    JE null_input_value2
    
    CMP CL, 0x00
    JE null_input_value2
    
    CMP CL, '-'   
    JE neg_value2
    
    JMP check_invalid_value2
    
neg_value2:
    MOV BL, 0x01
    INC ESI
    
check_invalid_value2:
    MOV CL, [ESI]
    
    CMP CL, 0x0A
    JE convert_value2

    CMP CL, 0x00
    JE convert_value2
    
    CMP CL, '0'
    JL invalid_char_value2
    
    CMP CL, '9'
    JG invalid_char_value2
    
    INC ESI
    JMP check_invalid_value2
    
convert_value2:
    LEA ESI, [value_str2]

    BT BX, 0x00
    JC skip_neg_sign_value2
    
    JMP to_int_value2
        
skip_neg_sign_value2:
    INC ESI
    
to_int_value2:
    MOV CL, [ESI]
    
    CMP CL, 0x0A
    JE convert_neg_value2
    
    CMP CL, 0x00
    JE convert_neg_value2
    
    SUB CL, '0'
    MUL EDI
    ADD EAX, ECX
    
    INC ESI
    JMP to_int_value2
    
convert_neg_value2:
    BT BX, 0x00
    JC affix_neg_sign_value2
    
    JMP save_value2
    
affix_neg_sign_value2:
    NEG EAX
    
; Before saving the integer conversion of value 2, check if it is unique.
save_value2:
    ; If value 2 is equal to value 1, prompt the user to enter another value for value 2.
    MOV EDX, [value1]
    CMP EDX, EAX
    JE invalid_unique_value2
    
    ; Otherwise, store the integer conversion (in register EAX) to the dedicated memory
    ; location, and proceed to entering value 3.
    MOV [value2], EAX
    JMP enter_value3
    
null_input_value2:
    PUSH error_null
    CALL _printf
    ADD ESP, 4
    
    JMP enter_value2
    
invalid_char_value2:
    PUSH error_invalid_char
    CALL _printf
    ADD ESP, 4
    
    JMP enter_value2

; Trap errors related to non-uniqueness of values.    
invalid_unique_value2:
    ; printf("Error: Please enter unique values")
    PUSH error_invalid_unique
    CALL _printf
    ADD ESP, 4
    
    ; Prompt the user to enter another value.
    JMP enter_value2
    
; =================================================================================
; Prompt the user to enter value 3, perform error trapping, and convert it
; to an integer if it is valid.

; The logic of this routine is analogous to that for value 3. Therefore, in the
; interest of brevity, the documentation for analogous instructions is omitted.
; ================================================================================= 
enter_value3:
    MOV EBX, 0x00000000
    
    PUSH input_prompt3
    CALL _printf
    ADD ESP, 4
    
    PUSH value_str3
    CALL _gets
    ADD ESP, 4
    
    MOV EAX, 0x00000000
    MOV ECX, 0x00000000
    
    LEA ESI, [value_str3]    
    MOV CL, [ESI]
    
    CMP CL, 0x0A
    JE null_input_value3
    
    CMP CL, 0x00
    JE null_input_value3
    
    CMP CL, '-'   
    JE neg_value3
    
    JMP check_invalid_value3
    
neg_value3:
    MOV BL, 0x01
    INC ESI
    
check_invalid_value3:
    MOV CL, [ESI]
    
    CMP CL, 0x0A
    JE convert_value3

    CMP CL, 0x00
    JE convert_value3
    
    CMP CL, '0'
    JL invalid_char_value3
    
    CMP CL, '9'
    JG invalid_char_value3
    
    INC ESI
    JMP check_invalid_value3
    
convert_value3:
    LEA ESI, [value_str3]

    BT BX, 0x00
    JC skip_neg_sign_value3
    
    JMP to_int_value3
        
skip_neg_sign_value3:
    INC ESI
    
to_int_value3:
    MOV CL, [ESI]
    
    CMP CL, 0x0A
    JE convert_neg_value3
    
    CMP CL, 0x00
    JE convert_neg_value3
    
    SUB CL, '0'
    MUL EDI
    ADD EAX, ECX
    
    INC ESI
    JMP to_int_value3
    
convert_neg_value3:
    BT BX, 0x00
    JC affix_neg_sign_value3
    
    JMP save_value3
    
affix_neg_sign_value3:
    NEG EAX
 
; Before saving the integer conversion of value 3, check if it is unique.       
save_value3:
    ; If value 3 is equal to value 1, prompt the user to enter another value for value 3.
    MOV EDX, [value1]
    CMP EDX, EAX
    JE invalid_unique_value3
    
    ; If value 3 is equal to value 2, prompt the user to enter another value for value 2.
    MOV EDX, [value2]
    CMP EDX, EAX
    JE invalid_unique_value3
    
    ; Otherwise, store the integer conversion (in register EAX) to the dedicated memory
    ; location, and proceed to getting the minimum among the three values.
    MOV [value3], EAX
    JMP get_minimum
    
null_input_value3:
    PUSH error_null
    CALL _printf
    ADD ESP, 4
    
    JMP enter_value3
    
invalid_char_value3:
    PUSH error_invalid_char
    CALL _printf
    ADD ESP, 4
    
    JMP enter_value3

invalid_unique_value3:
    PUSH error_invalid_unique
    CALL _printf
    ADD ESP, 4
    
    JMP enter_value3
    
; =================================================================================
; Identify the minimum among the three entered values.
; =================================================================================
get_minimum:
    ; Compare value 3 and value 1. As a result of the previous instructions, note
    ; that register EAX still stores value 3.
    MOV EDX, [value1]
    CMP EDX, EAX
    
    ; If value 1 (stored in EDX) is less than value 3 (stored in EAX), get the
    ; smaller value between value 1 and value 2
    JL min_value1_vs_value2
    
    ; Otherwise, get the smaller value between value 2 and value 3. 
    MOV EDX, [value2]
    CMP EDX, EAX
    
    ; If value 2 (stored in EDX) is less than value 3 (stored in EAX), then value 2
    ; is the minimum value.
    JL min_value_edx
    
    ; Otherwise, value 3 is the minimum value.  
    JMP min_value_eax
    
min_value1_vs_value2:
    ; Store value 2 in register EAX, and compare it with value 1 (still stored
    ; in register EDX).
    MOV EAX, [value2]
    CMP EDX, EAX
    
    ; If value 1 (stored in EDX) is less than value 2 (stored in EAX), then value 1
    ; is the minimum value.
    JL min_value_edx
    
    ; Otherwise, value 2 is the minimum value.
    JMP min_value_eax

; Store the minimum value in register ESI. 
min_value_edx:
    MOV ESI, EDX
    JMP get_maximum
    
min_value_eax:
    MOV ESI, EAX
    
    ; No need for JMP since it is the next instruction.

; =================================================================================
; Identify the maximum among the three entered values.
; =================================================================================
get_maximum:
    ; In order to make the routine analogous to that for identifying the minimum,
    ; store value 3 in register EAX before comparing value 3 and value 1.
    MOV EAX, [value3]
    MOV EDX, [value1]
    CMP EDX, EAX
    
    ; If value 1 (stored in EDX) is greater than value 3 (stored in EAX), get the
    ; higher value between value 1 and value 2
    JG max_value1_vs_value2
    
    ; Otherwise, get the higher value between value 2 and value 3. 
    MOV EDX, [value2]
    CMP EDX, EAX
    
    ; If value 2 (stored in EDX) is greater than value 3 (stored in EAX), then value 2
    ; is the maximum value.
    JG max_value_edx
    
    ; Otherwise, value 3 is the maximum value.  
    JMP max_value_eax
    
max_value1_vs_value2:
    ; Store value 2 in register EAX, and compare it with value 1 (still stored
    ; in register EDX).
    MOV EAX, [value2]
    CMP EDX, EAX
    
    ; If value 1 (stored in EDX) is greater than value 2 (stored in EAX), then value 1
    ; is the maximum value.
    JG max_value_edx
    
    ; Otherwise, value 2 is the maximum value.
    JMP max_value_eax

; Store the maximum value in register EDI.     
max_value_edx:
    MOV EDI, EDX
    JMP display_min_max
    
max_value_eax:
    MOV EDI, EAX
    
    ; No need for JMP since it is the next instruction.

; =================================================================================
; Display the minimum and maximum values (in this order).
; =================================================================================
display_min_max:
    ; printf("Minimum:\n")
    ; printf("%d", min_value)
    ; printf("\n")
    PUSH message_min
    CALL _printf
    ADD ESP, 4
    
    ; ESI stores the minimum value. This is unaffected by the C method call.
    PUSH ESI
    PUSH int_flag
    CALL _printf
    ADD ESP, 8
    
    PUSH newline
    CALL _printf
    ADD ESP, 4
    
    ; printf("Maximum:\n")
    ; printf("%d", max_value)
    ; printf("\n")
    PUSH message_max
    CALL _printf
    ADD ESP, 4
    
    ; EDI stores the maximum value. This is unaffected by the C method call.
    PUSH EDI
    PUSH int_flag
    CALL _printf
    ADD ESP, 8
    
    PUSH newline
    CALL _printf
    ADD ESP, 4
    
; =================================================================================
; Normalize the three entered values following this formula:
;     x_normalized = (x - min(x)) / (max(x) - min(x))
 
; A sanity check is that two of the three normalized values should be 0,0 and 1,0,
; representing the extremes (the minimum and maximum, respectively).
; ================================================================================= 
    ; printf("Normalized output:\n")
    PUSH message_norm
    CALL _printf
    ADD ESP, 4

    ; Store the denominator max(x) - min(x) in register EDI.   
    ; Note that EDI stores the maximum value and ESI stores the minimum value. 
    SUB EDI, ESI
    
    ; NORMALIZATION FOR VALUE 1
    ; Store the numerator x - min(x) in register EAX.
    MOV EAX, [value1]
    SUB EAX, ESI
    
    ; Note that the numerator is always nonnegative. The justification is as follows:
    ; - If x is nonnegative and min(x) is nonnegative, then x - min(x) >= 0
    ; - If x is nonnegative and min(x) is negative, then x - min(x) >= 0
    ; - If x is negative and min(x) is negative, then x - min(x) = x + |min(x)|.
    ;   Hence, x and |min(x)| have opposite signs. Since |min(x)| > |x|, the sign
    ;   of the final answer is the sign of |min(x)|, i.e., nonnegative. To illustrate,
    ;   consider -6 - (-9) = -6 + 9 = 3. 
    
    ; An analogous justification can be used to prove that the denominator is
    ; always nonnegative as well.
    
    ; Since 32-bit division is performed, EDX:EAX serves as the dividend. In this regard, 
    ; the sign extension is stored in EDX; the sign extension is 0x00000000 by the
    ; justification above.
    
    ; Use DIV in order to maximize the 32-bit capacity. It is safe to use unsigned
    ; division since both the numerator and denominator are nonnegative.
    MOV EDX, 0x00000000
    DIV EDI
        
    ; printf("%d,%u; ", EAX, EDX)
    
    ; Use %u for the remainder to handle extreme cases, such as this:
    ; - Raw values: [-2147483648, 2147483646, 0]
    ; - Normalized value of 0 if %d is used: -2147483648
    ; - Normalized value of 0 if %u is used: 2147483648
    
    ; The usage of %u forces the contents of EDX (remainder) to be interpeted as
    ; unsigned, which is the intention of the normalization procedure.
    PUSH EDX
    PUSH EAX
    PUSH norm_format_semicolon
    CALL _printf
    ADD ESP, 12
    
    ; NORMALIZATION FOR VALUE 2 (analogous to the procedure for value 1)    
    MOV EAX, [value2]
    SUB EAX, ESI
    
    MOV EDX, 0x00000000
    DIV EDI
    
    ; printf("%d,%u; ", EAX, EDX)
    PUSH EDX
    PUSH EAX
    PUSH norm_format_semicolon
    CALL _printf
    ADD ESP, 12
      
    ; NORMALIZATION FOR VALUE 3 (analogous to the procedure for value 1)     
    MOV EAX, [value3]
    SUB EAX, ESI
    
    MOV EDX, 0x00000000
    DIV EDI
        
    ; printf("%d,%u", EAX, EDX)
    PUSH EDX
    PUSH EAX
    PUSH norm_format_no_semicolon
    CALL _printf
    ADD ESP, 12 

; =================================================================================
; Ask the user if they would like to continue, and perform the necessary error
; trapping for null and invalid input.

; Valid responses are "Y", "N", "yes", and "no". Case-insensitive string matching
; is employed in the interest of flexibility and usability.
; =================================================================================     
continue:
    ; printf("Do you want to continue? (Y/N/yes/no)")
    PUSH continue_prompt
    CALL _printf
    ADD ESP, 4
    
    ; gets(continue_input)
    PUSH continue_input
    CALL _gets
    ADD ESP, 4
    
    ; Since the input is from the DOS/CLI prompt, a string is considered null
    ; if the user presses the enter key without typing anything. Hence, this code
    ; checks if the first character of the string is the newline (ASCII: 0x0A). 
    CMP byte [continue_input], 0x0A
    JE null_input_continue
    
    ; Technically, a null string is a string containing only the null terminator.
    ; Although the input is from the DOS/CLI prompt (necessitating the enter key 
    ; to be pressed), this code still checks if the first character of the string 
    ; is the null terminator for additional insurance.
    CMP byte [continue_input], 0x00
    JE null_input_continue
    
    ; Check the first character. The only valid first characters are 'Y', 'y'
    ; 'N', and 'n'.
    CMP byte [continue_input], 'Y'
    JE yes_2nd_letter
    
    CMP byte [continue_input], 'y'
    JE yes_2nd_letter
    
    CMP byte [continue_input], 'N'
    JE no_2nd_letter
    
    CMP byte [continue_input], 'n'
    JE no_2nd_letter
    
    JMP invalid_input_continue

; If the first character indicates an affirmative response, the only valid second 
; characters are 'E' or 'e' (if the input is 'yes' or its case-insensitive equivalents) 
; and '\0' or '\n' (if the input is 'y' or 'Y').   
yes_2nd_letter:
    CMP byte [continue_input + 1], 'E'
    JE yes_3rd_letter
    
    CMP byte [continue_input + 1], 'e'
    JE yes_3rd_letter
    
    CMP byte [continue_input + 1], 0x00
    JE start_program
    
    CMP byte [continue_input + 1], 0x0A
    JE start_program
    
    JMP invalid_input_continue

; If the first character indicates an affirmative response, the only valid third
; characters are 'S' or 's' (if the input is 'yes' or its case-insensitive equivalents). 
yes_3rd_letter:
    CMP byte [continue_input + 2], 'S'
    JE yes_terminator
    
    CMP byte [continue_input + 2], 's'
    JE yes_terminator

    JMP invalid_input_continue

; If the first character indicates an affirmative response, the only valid fourth
; characters are '\0' or '\n' (if the input is 'yes' or its case-insensitive equivalents).        
yes_terminator:
    CMP byte [continue_input + 3], 0x00
    JE start_program
    
    CMP byte [continue_input + 3], 0x0A
    JE start_program
    
    JMP invalid_input_continue

; If the first character indicates a negative response, the only valid second 
; characters are 'O' or 'o' (if the input is 'no' or its case-insensitive equivalents) 
; and '\0' or '\n' (if the input is 'n' or 'N').   
no_2nd_letter:
    CMP byte [continue_input + 1], 'O'
    JE no_terminator
    
    CMP byte [continue_input + 1], 'o'
    JE no_terminator
    
    CMP byte [continue_input + 1], 0x00
    JE finish_program
    
    CMP byte [continue_input + 1], 0x0A
    JE finish_program
    
    JMP invalid_input_continue

; If the first character indicates a negative response, the only valid third
; characters are '\0' or '\n' (if the input is 'no' or its case-insensitive equivalents).        
no_terminator:
    CMP byte [continue_input + 2], 0x00
    JE finish_program
    
    CMP byte [continue_input + 2], 0x0A
    JE finish_program
    
    JMP invalid_input_continue

; Trap errors related to null input.
null_input_continue:
    ; printf("Error: Null input")
    PUSH error_null
    CALL _printf
    ADD ESP, 4
    
    JMP continue

; Trap errors related to invalid input (unrecognized string).    
invalid_input_continue:
    ; printf("Error: Y, N, yes, or no only (not case sensitive)")
    PUSH error_invalid_input
    CALL _printf
    ADD ESP, 4
    
    JMP continue

; Terminate the program gracefully.
finish_program:    
    xor eax, eax
    ret