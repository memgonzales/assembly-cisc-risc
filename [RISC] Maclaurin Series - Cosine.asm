# The Cosine function of x can be computed by using the mathematical series:
#    summation from n = 0 to infinity of ((-1)^n / (2n)!) * x^(2n)
# Note: the series assume that x is in radian.

# Write a RISC-V assembly language to compute for the function using the mathematical series 
#    up to 6 terms (n=0 to 5).

# Input [in the memory already]: Memory location x (single float) in radian
# Output:
#    1.) the function name [Dialog box]
#    2.) the value of each term (not cumulative) [I/O console]
#    3.) the final answer [Dialog box]

.globl main

.macro NEWLINE
	li a7, 11			# Print an ASCII character on the console.
	li a0, 10			# ASCII value of line feed
	ecall
.end_macro

.macro DONE
	li a7, 10			# Exit the program with code 0.
	ecall
.end_macro

.data
	x: .float -0.7853981634		# Angle whose cosine is to be approximated via the Maclaurin series
					# Assume that this angle is given in radians:
					#    -pi/4 radians = -45 degrees
	
	# Output messages
	function_name: .asciz "Maclaurin series (special case of Taylor series)\nfor the cosine function of x = "
	approx: .asciz "The Maclaurin approximation for the cosine of the given angle is "
	
	term_label: .asciz "Term "
	colon: .asciz ": "
	
.text
main:
		li a7, 60		# Author: Mark Edward M. Gonzales, Section S15
		la a0, function_name	# Display the function name on a dialog box.
		la s3, x		# Include the value of the angle (x) to make the dialog box
		flw fa1, (s3)		#    message more informative.
		ecall
	
		fmv.s fa3, fa1		# fa3 stores the value of the angle (x).
		li a3, -1		# a3 and a4 store constants in the Maclaurin approximation
		li a4, 2		#    of cosine.
	
		fcvt.s.w fa1, x0	# fa1 is the accumulator for the approximation of cosine.
					# Initialize it to 0 since this accumulator is for a summation.
		
		li a6, 6		# a6 stores the number of terms.
		li a5, 0		# a5 is the current term number (zero-based).
		
init_term:	beq a5, a6, final_ans	# Compute the approximation up to n = 5 (6 terms).
		
		mv t1, a5		# t1 temporarily stores the current term number (zero-based)
					#    for use in intermediate computations.

					# Initialize these accumulators to 1 since they are for products:
		li s1, 1		#  - s1 is the accumulator for the power of -1 (numerator 
					#    of the coefficient) of a term in the Maclaurin approximation.
		li s2, 1		#  - s2 is the accumulator for the factorial (denominator
					#    of the coefficient) of a term in the Maclaurin approximation.
		fcvt.s.w fs3, s2	#  - fs3 is the accumulator for raising the angle (x) 
					#    to the designated power in the Maclaurin approximation.
					#    A floating-point register is used since x is a single-
					#    precision floating-point value.
		
		beq a5, x0, calc_term	# If the current term number is 0, proceed directly to computing
					#    the value of the term since (-1)^0 = 1, (2*0)! = 1, and 
					#    x^(2*0) = 1. The accumulators are already initialized to 1.
		
pow_neg_one:	mul s1, s1, a3		# Multiply a3 by itself t1 times, and store the product in s1.
		addi t1, t1, -1		# Since a3 stores -1 and t1 refers to the term number, this is
		bne t1, x0, pow_neg_one	#    equivalent to (-1)^n, the numerator of the coefficient.
		
		mv t1, a5		# Restore the value of t1 in preparation for computing the
					#    denominator of the coefficient.
		mul t1, t1, a4		# Multiply t1 by a4 (the value of which is 2) since the denominator
					#    of the coefficient is (2n)!
					
factorial:	mul s2, s2, t1		# In the 1st iteration, s2 (which stores the value 1) is multiplied
		addi t1, t1, -1		#    by t1 (which stores the value 2n). In the 2nd iteration, the product
		bne t1, x0, factorial	#    is multiplied by 2n - 1, and so on. This is equivalent to (2n)!
		
		mv t1, a5		# Restore the value of t1 in preparation for computing the
					#    value of x^(2n).
		mul t1, t1, a4		# Multiply t1 by a4 (the value of which is 2) since the exponent
					#    is 2n.
					
pow_x:		fmul.s fs3, fs3, fa3	# Multiply fa3 by itself t1 times, and store the product in fs3.
		addi t1, t1, -1		# Since fa3 stores the angle (x) and t1 stores the value 2n, this is
		bne t1, x0, pow_x	#    equivalent to x^(2n).
			
calc_term:	fcvt.s.w fs1, s1	# Compute the value of a term.
		fcvt.s.w fs2, s2	# Convert the numerator and denominator of the coefficient
					#    to floating-point values to allow floating-point arithmetic.
					
		fdiv.s ft1, fs1, fs2	# Compute the value of the coefficient, and store it in ft1.
		fmul.s fa0, ft1, fs3	# Multiply the coefficient and x^(2n), which are stored in
					#    ft1 and fs3, respectively, and store the product in fa0.
					#    fa0 now stores the non-cumulative value of a term.
	
		fadd.s fa1, fa1, fa0	# Cumulatively compute the sum of the terms, and store it in fa1.
		
		addi a5, a5, 1		# Advance to the next term.
		
		li a7, 4		# Print a string on the console.
		la a0, term_label	# Print the label "Term ".
		ecall
		
		li a7, 1		# Print an integer on the console.
		mv a0, a5		# Print the term number (one-based). For instance, if n = 0,
					#    "Term 1" is printed. The shift to one-based numbering is 
					#    handled by the increment meant to advance to the next term.
		ecall
		
		li a7, 4		# Print a string on the console.
		la a0, colon		# Print the colon separating the term number from the value.
		ecall
		
		li a7, 2		# Print a floating-point number on the console.
		ecall			# The non-cumulative value of the term is already in fa0.
		
		NEWLINE
		
		j init_term		# Proceed to the next term of the Maclaurin approximation.
			
final_ans:	li a7, 60		# Launch a message dialog that displays a float.
		la a0, approx		# The Maclaurin approximation is already in fa1.
		ecall			# Expected answer (calculator value): 
					#    cos(-pi/4) = sqrt(2) / 2 = 0.70710678
					# Displayed answer can deviate by a few fractional places.
		
		DONE			# Terminate the program.
