.include "./cs47_proj_macro.asm"
.include "./cs47_proj_procs.asm"

# data section
.data 
msg1: .asciiz "Enter a value for a: "
msg2: .asciiz "Enter a value for b: "
msg3: .asciiz "Enter an operation (+, -, *, /): "
char: .space 2
matchMsg: .asciiz "   [PASS]"
unmatchMsg: .asciiz "   [FAIL]" 
normal: .asciiz "  normal=> "
logical: .asciiz " =  logical=> "
Q:	.asciiz "Q:"
R:	.asciiz "R:"
HI:	.asciiz "HI:"
LO:	.asciiz " LO:"
line: .asciiz "\n"
signp: .asciiz " + "
signm: .asciiz " - "
signt: .asciiz " * "
signd:  .asciiz " / "
error: .asciiz "ERROR: please enter a valid operation"

.text
.globl main
main:
	print_str(msg1)	#prompt the user for a
	read_int($s0)
	print_str(msg2)	#prompt the user for b
	read_int($s1)
	print_str(msg3) #prompt the user for an operation
	read_char(char)
	print_str(line)
	
	la $s2, char	#store the operation
	lb $a2, 0($s2)
	add $a0, $s0, $zero
	add $a1, $s1, $zero
	#check for add, sub, mul, or div in order to print correct result
	beq $a2, '+', ADDMAIN
	beq $a2, '-', SUBMAIN
	beq $a2, '*', MULMAIN
	beq $a2, '/', DIVMAIN
	print_str(error) #print an error message if the operation entered is invalid
	exit
	
	ADDMAIN:
		jal au_logical #perform addition logical
		move $s4, $v0
		print_reg_int($s0)
		print_str(signp)
		print_reg_int($s1)
		print_str(logical)
		print_reg_int($s4)
		add $a0, $s0, $zero
		add $a1, $s1, $zero
		jal au_normal	#perfrom addition normal
		move $s5, $v0
		print_str(normal)
		print_reg_int($s5)
		beq $s4, $s5, PRINT_MATCHED	#compare normal and logical addition
		bne $s4, $s5, PRINT_NOT_MATCHED
	SUBMAIN:
		jal au_logical	#perform subtraction logical
		move $s4, $v0
		print_reg_int($s0)
		print_str(signm)
		print_reg_int($s1)
		print_str(logical)
		print_reg_int($s4)
		add $a0, $s0, $zero
		add $a1, $s1, $zero
		jal au_normal	#perform subtracton normal
		move $s5, $v0
		print_str(normal)
		print_reg_int($s5)
		beq $s4, $s5, PRINT_MATCHED	#check normal and logical subtraction
		bne $s4, $s5, PRINT_NOT_MATCHED
	MULMAIN:
		jal au_logical	#perform logical multplication
		move $s3, $v0
		move $s4, $v1
		print_reg_int($s0)
		print_str(signt)
		print_reg_int($s1)
		print_str(logical)
		print_str(HI)
		print_reg_int($s3)
		print_str(LO)
		print_reg_int($s4)
		add $a0, $s0, $zero
		add $a1, $s1, $zero
		jal au_normal	#perform normal multplication	
		move $s5, $v0
		move $s6, $v1
		print_str(normal)
		print_str(HI)
		print_reg_int($s5)
		print_str(LO)
		print_reg_int($s6)
		bne $s3, $s5, PRINT_NOT_MATCHED	#check normal and logical multplication
		bne $s4, $s6, PRINT_NOT_MATCHED
		beq $s3, $s5, PRINT_MATCHED
	DIVMAIN:
		jal au_logical	#perform logical division
		move $s3, $v0
		move $s4, $v1
		print_reg_int($s0)
		print_str(signd)
		print_reg_int($s1)
		print_str(logical)
		print_str(Q)
		print_reg_int($s3)
		print_str(R)
		print_reg_int($s4)
		add $a0, $s0, $zero
		add $a1, $s1, $zero
		jal au_normal	#perform normal division
		move $s5, $v0
		move $s6, $v1
		print_str(normal)
		print_str(Q)
		print_reg_int($s5)
		print_str(R)
		print_reg_int($s6)
		bne $s3, $s5, PRINT_NOT_MATCHED	#check normal and logical division
		bne $s4, $s6, PRINT_NOT_MATCHED
		beq $s3, $s5, PRINT_MATCHED

	PRINT_MATCHED:
		print_str(matchMsg)	#logical and normal operation matched
		exit
	PRINT_NOT_MATCHED:
		print_str(unmatchMsg) #logical and normal operation did not match
		exit
