.include "./cs47_proj_macro.asm"
.text
#-----------------------------------------------
# C style signature 'printf(<format string>,<arg1>,
#			 <arg2>, ... , <argn>)'
#
# This routine supports %s and %d only
#
# Argument: $a0, address to the format string
#	    All other addresses / values goes into stack
#-----------------------------------------------
printf:
	#store RTE - 5 *4 = 20 bytes
	addi	$sp, $sp, -24
	sw	$fp, 24($sp)
	sw	$ra, 20($sp)
	sw	$a0, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1,  8($sp)
	addi	$fp, $sp, 24
	# body
	move 	$s0, $a0 #save the argument
	add     $s1, $zero, $zero # store argument index
printf_loop:
	lbu	$a0, 0($s0)
	beqz	$a0, printf_ret
	beq     $a0, '%', printf_format
	# print the character
	li	$v0, 11
	syscall
	j 	printf_last
printf_format:
	addi	$s1, $s1, 1 # increase argument index
	mul	$t0, $s1, 4
	add	$t0, $t0, $fp # all print type assumes 
			      # the latest argument pointer at $t0
	addi	$s0, $s0, 1
	lbu	$a0, 0($s0)
	beq 	$a0, 'd', printf_int
	beq	$a0, 's', printf_str
	beq	$a0, 'c', printf_char
printf_int: 
	lw	$a0, 0($t0) # printf_int
	li	$v0, 1
	syscall
	j 	printf_last
printf_str:
	lw	$a0, 0($t0) # printf_str
	li	$v0, 4
	syscall
	j 	printf_last
printf_char:
	lbu	$a0, 0($t0)
	li	$v0, 11
	syscall
	j 	printf_last
printf_last:
	addi	$s0, $s0, 1 # move to next character
	j	printf_loop
printf_ret:
	#restore RTE
	lw	$fp, 24($sp)
	lw	$ra, 20($sp)
	lw	$a0, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1,  8($sp)
	addi	$sp, $sp, 24
	jr $ra
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
#####################################################################
au_logical:
	addi $sp, $sp, -24
	sw   $fp, 24($sp)
	sw   $ra, 20($sp)
	sw   $a0, 16($sp)
	sw   $a1, 12($sp)
	sw   $a2, 8($sp)
	addi $fp, $sp, 24
	#Check for add, sub, mul, or div
	beq $a2, '+', ADDL
	beq $a2, '-', SUBL
	beq $a2, '*', MULL
	beq $a2, '/', DIVL
	ADDL:			#perform +
		jal add_logical
		j ENDL
	SUBL:			#perform -
		jal sub_logical
		j ENDL
	MULL:			#perform *
		jal mul_logical
		j ENDL
	DIVL:			#perform /
		jal div_logical
		j ENDL
ENDL:
	lw   $fp, 24($sp)
	lw   $ra, 20($sp)
	lw   $a0, 16($sp)
	lw   $a1, 12($sp)
	lw   $a2,  8($sp)
	addi $sp, $sp, 24
	jr	$ra
#####################################################################
# add_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
# Return:
#	$v0: ($a0+$a1)
# Notes:Saves $a2 because the the function will change $a2 that may 
#	be needed later
#####################################################################	
add_logical:
	addi	$sp, $sp, -24
	sw   	$fp, 24($sp)
	sw   	$ra, 20($sp)
	sw   	$a0, 16($sp)
	sw   	$a1, 12($sp)
	sw	$a2,  8($sp)
	addi 	$fp, $sp, 24
	
	li $a2, 0x00000000	#pass addition argument into add_sub_logical
	jal add_sub_logical	#call add_sub_logical
				#add_sub_logical places return value
	lw   	$fp, 24($sp)
	lw   	$ra, 20($sp)
	lw   	$a0, 16($sp)
	lw   	$a1, 12($sp)
	lw	$a2,  8($sp)
	addi	$sp, $sp, 24
	jr 	$ra 
#####################################################################
# sub_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
# Return:
#	$v0: ($a0-$a1)
# Notes:
#       Saves $a2 because the the function will change $a2 that may 
#	be needed later
#####################################################################
sub_logical:
	addi	$sp, $sp, -24
	sw   	$fp, 24($sp)
	sw   	$ra, 20($sp)
	sw   	$a0, 16($sp)
	sw   	$a1, 12($sp)
	sw	$a2,  8($sp)
	addi 	$fp, $sp, 24
	
	li $a2, 0xFFFFFFFF	#pass subtraction arguemnt into add_sub_logical
	jal add_sub_logical	#call add_sub_logical
				#add_sub_logical places return value
	lw   	$fp, 24($sp)
	lw   	$ra, 20($sp)
	lw   	$a0, 16($sp)
	lw   	$a1, 12($sp)
	lw	$a2,  8($sp)
	addi	$sp, $sp, 24
	jr 	$ra	
#####################################################################
# add_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: 0x0000000 for addition, 0xffffffff for subtraction
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1)
# Notes:
#       Fuction does addition or subtraction depending on $a2
#####################################################################
add_sub_logical:
	addi	$sp, $sp, -52
	sw   	$fp,  52($sp)
	sw   	$ra,  48($sp)
	sw   	$a0,  44($sp)
	sw   	$a1,  40($sp)
	sw	$a2,  36($sp)
	sw	$s0,  32($sp)
	sw	$s2,  28($sp)
	sw	$s7,  24($sp)
	sw	$s3,  20($sp)
	sw	$s4,  16($sp)
	sw	$s5,  12($sp)
	sw	$s6,   8($sp)
	addi 	$fp, $sp, 52
	
	add $v0, $zero, $zero	#zero out needed registers
	add $s0, $zero, $zero		
	extract_nth_bit($s2, $a2, $zero) #check to addidion or subtraction
	beqz $s2, CONT
	nor $a1, $a1, $zero	#invert $a1 if subtraction
	CONT:
		extract_nth_bit($s3, $a0, $s0)	#get current bit in $a0, and $a1
		extract_nth_bit($s4, $a1, $s0)
		xor $s5, $s2, $s3	#perform addiition or subtraction on both bits
		xor $s6, $s5, $s4
		insert_one_to_nth_bit($v0, $s0, $s6, $s7)
		xor $s5, $s3, $s4
		and $s6, $s5, $s2
		and $s5, $s3, $s4
		or  $s2, $s6, $s5
	addi $s0, $s0, 1
	bne $s0, 32, CONT		#continue add or sub on all 32 bits

	lw   	$fp, 52($sp)
	lw   	$ra, 48($sp)
	lw   	$a0, 44($sp)
	lw   	$a1, 40($sp)
	lw	$a2,  36($sp)
	lw	$s0,  32($sp)
	lw	$s2,  28($sp)
	lw	$s7,  24($sp)
	lw	$s3,  20($sp)
	lw	$s4,  16($sp)
	lw	$s5,  12($sp)
	lw	$s6,  8($sp)
	addi	$sp, $sp, 52
	jr 	$ra	# jump to caller 
#####################################################################
# twos_compliment_64bit
# Argument:
# 	$a0: upper 32 bits
#	$a1: lower 32 bits
# Return:
#	$v0: twos compliment of $a1
# 	$v1: inversion of $a0 + carry over bit
#####################################################################	
twos_compliment_64bit:
	addi	$sp, $sp, -28
	sw   	$fp, 28($sp)
	sw   	$ra, 24($sp)
	sw   	$a0, 20($sp)
	sw	$a1, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	addi 	$fp, $sp, 28	
	
	move $s0, $a1		#invert first number and add one
	nor $a0, $a0, $zero
	nor $s0, $s0, $zero
	li $a1, 1
	jal add_logical
	move $s1, $v0
	move $a1, $v1
	move $a0, $s0		#add second number by carry over bit
	jal add_logical
	move $s0, $v0
	move $v0, $s1
	move $v1, $s0
	
	lw   	$fp, 28($sp)
	lw   	$ra, 24($sp)
	lw   	$a0, 20($sp)
	lw	$a1, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 28
	jr 	$ra	# jump to caller
#####################################################################
# bit_replicator
# Argument:
# 	$a0: the bit needed to be replicated
# Return:
#	$v0: 0x00000000, 0xffffffff, depending on $a0
#####################################################################	
bit_replicator:
	addi	$sp, $sp, -24
	sw   	$fp, 24($sp)
	sw   	$ra, 20($sp)
	sw   	$a0, 16($sp)
	sw   	$s0, 12($sp)
	sw   	$s1, 8($sp)
	addi 	$fp, $sp, 24
	
	add $v0, $zero, $zero	#zero out needed registers
	add $s0, $zero, $zero
	add $s1, $zero, $zero
	BRLOOP:
		extract_nth_bit($t0, $a0, $zero)	#get the desired bit
		insert_one_to_nth_bit($v0, $s1, $t0, $t9)	#copy bit 32 times
		addi $s1, $s1, 1
		bne $s1, 32, BRLOOP
		
	lw   	$fp, 24($sp)
	lw   	$ra, 20($sp)
	lw   	$a0, 16($sp)
	lw   	$s0, 12($sp)
	lw   	$s1, 8($sp)
	addi	$sp, $sp, 24
	jr 	$ra	# jump to caller
#####################################################################
# twos_compliment
# Argument:
# 	$a0: the number needed to be converted to twos_compliment
# Return:
#	$v0: twos compliment of $a0
# Notes: Saves $a1 so it can be used later
#####################################################################						
twos_compliment:
	addi	$sp, $sp, -20
	sw   	$fp, 20($sp)
	sw   	$ra, 16($sp)
	sw   	$a0, 12($sp)
	sw	$a1, 8($sp)
	addi 	$fp, $sp, 20
	
	add $a1, $zero, $zero	#zero out register
	li $a1, 1		#invert number, and add 1
	add $v0, $zero, $zero	#zero out register
	nor $a0, $a0, $zero
	jal add_logical
	
	lw   	$fp, 20($sp)
	lw   	$ra, 16($sp)
	lw   	$a0, 12($sp)
	lw	$a1, 8($sp)
	addi	$sp, $sp, 20
	jr 	$ra	# jump to caller
#####################################################################
# unsigned_multiplication
# Argument:
# 	$a0: first number
#	$a1: second number
# Return:
#	$v0: LO value of ($a0*$a1)
# 	$v1: HI value of ($a0*$a1)
# Notes: numbers need to be unsigned
#####################################################################	
usigned_multiplication:
	addi	$sp, $sp, -44
	sw   	$fp, 44($sp)
	sw   	$ra, 40($sp)
	sw   	$a0, 36($sp)
	sw   	$a1, 32($sp)
	sw	$s0, 28($sp)
	sw	$s1, 24($sp)
	sw	$s2, 20($sp)
	sw	$s3, 16($sp)
	sw	$s4, 12($sp)
	sw	$s5,  8($sp)
	addi 	$fp, $sp, 44
	
	add $s2, $zero, $zero	#I, zero out register
	add $s3, $zero, $zero	#H, zero out register
	add $s4, $zero, $zero	#R, zero out register
	add $s5, $zero, $zero	#X, zero out register
	move $s0, $a0 		#M
	move $s1, $a1		#L
	li $t1, 31
	UMLOOP:
		extract_nth_bit($t0, $s1, $zero) 
		move $a0, $t0
		jal bit_replicator
		move $s4, $v0		#R= {32L[0]}
		and $s5, $s0, $s4	#X = M & R
		move $a0, $s3
		move $a1, $s5
		jal add_logical
		move $s3, $v0		#H = H + X
		srl  $s1, $s1, 1	#L = L >> 1
		extract_nth_bit($t0, $s3, $zero)
		insert_one_to_nth_bit($s1, $t1, $t0, $t2)	#L[31] = H[0]
		srl $s3, $s3, 1		#H = H >> 1	
	addi $s2, $s2, 1		#I = I + 1
	bne $s2, 32, UMLOOP
	move $v0, $s1			#return HI
	move $v1, $s3			#return LO
	
	lw   	$fp, 44($sp)
	lw   	$ra, 40($sp)
	lw   	$a0, 36($sp)
	lw   	$a1, 32($sp)
	lw	$s0,  28($sp)
	lw	$s1,  24($sp)
	lw	$s2,  20($sp)
	lw	$s3,  16($sp)
	lw	$s4,  12($sp)
	lw	$s5,  8($sp)
	addi	$sp, $sp, 44
	jr 	$ra	# jump to caller 	
#####################################################################
# mul_logical
# Argument:
# 	$a0: first number
#	$a1: second number
# Return:
#	$v0: LO value of ($a0*$a1)
# 	$v1: HI value of ($a0*$a1)
# Notes: makes numbers unsigned then calls unsigend_multiplication
#####################################################################		
mul_logical:
	addi	$sp, $sp, -36
	sw   	$fp, 36($sp)
	sw   	$ra, 32($sp)
	sw   	$a0, 28($sp)
	sw   	$a1, 24($sp)
	sw	$s0,  20($sp)
	sw	$s1,  16($sp)
	sw	$s2,  12($sp)
	sw	$s3,  8($sp)
	addi 	$fp, $sp, 36
	
	li $s0, 31
 	extract_nth_bit($s2, $a0, $s0)
	extract_nth_bit($s3, $a1, $s0)
	xor $s2, $s2, $s3	#save the final sigh, + or -
	move $s0, $a0
	move $s1, $a1
	bgtz $s0, FIRSTPOS	#check if the first number is negative
	move $a0, $s0
	jal twos_compliment	#make first number positive
	move $s0, $v0
	FIRSTPOS:
		bgtz $s1, BOTHPOS	#check if second number is negative
		move $a0, $s1
		jal twos_compliment	#make second number positive
		move $s1, $v0
	BOTHPOS:
		move $a0, $s0
		move $a1, $s1
		jal usigned_multiplication	#perform unsigned multiplication
		move $s0, $v0
		move $s1, $v1
		beqz  $s2, ENDMUL	#check if final result needs to be negative
		move $a0, $s0
		move $a1, $s1
		jal twos_compliment_64bit	#make final result negative
		move $s0, $v0
		move $s1, $v1
	ENDMUL:
	move $v0, $s0		#return HI
	move $v1, $s1		#return LO
	
	lw   	$fp, 36($sp)
	lw   	$ra, 32($sp)
	lw   	$a0, 28($sp)
	lw   	$a1, 24($sp)
	lw	$s0,  20($sp)
	lw	$s1,  16($sp)
	lw	$s2,  12($sp)
	lw	$s3,  8($sp)
	addi	$sp, $sp, 36
	jr 	$ra	# jump to caller 
#####################################################################
# unsigned_division
# Argument:
# 	$a0: first number
#	$a1: second number
# Return:
#	$v0: ($a0/$a1)
# 	$v1: remainder of ($a0/$a1)
# Notes: numbers need to be unsigned
#####################################################################		
unsigned_division:
	addi	$sp, $sp, -40
	sw   	$fp, 40($sp)
	sw   	$ra, 36($sp)
	sw   	$a0, 32($sp)
	sw   	$a1, 28($sp)
	sw	$s0,  24($sp)
	sw	$s1,  20($sp)
	sw	$s2,  16($sp)
	sw	$s3,  12($sp)
	sw	$s4,  8($sp)
	addi 	$fp, $sp, 40

	move $s0, $a0 #DIVIDEND  Q
	move $s1, $a1 #DIVISOR   D
	add $s2, $zero, $zero #I, zero out register
	add $s3, $zero, $zero #R, zero out register
	li $t1, 31
	li $t2, 1
	DIVLOOP:
		sll $s3, $s3, 1	#R = R << 1
		extract_nth_bit($t0, $s0, $t1)
		insert_one_to_nth_bit($s3, $zero, $t0, $t9) #R[0] = Q[31]
		sll $s0, $s0, 1		#Q = Q << 1
		move $a0, $s3		
		move $a1, $s1
		jal sub_logical		#S = R - D
		move  $s4, $v0		#Check: S < 0 
		bltz  $s4, DIVCONT	
		move $s3, $s4		#R = S
		insert_one_to_nth_bit($s0, $zero, $t2, $t9) #Q[0] = 1
	DIVCONT:
		addi $s2, $s2, 1	#I = I + 1
		bne $s2, 32, DIVLOOP	# loop until I < 32		
	move $v0, $s0	#set $a0 / $a1
	move $v1, $s3	#set $a0 % $a1
	
	lw   	$fp,  40($sp)
	lw   	$ra,  36($sp)
	lw   	$a0,  32($sp)
	lw   	$a1,  28($sp)
	lw	$s0,  24($sp)
	lw	$s1,  20($sp)
	lw	$s2,  16($sp)
	lw	$s3,  12($sp)
	lw	$s4,   8($sp)
	addi	$sp, $sp, 40
	jr 	$ra	# jump to caller 
#####################################################################
# div_logical
# Argument:
# 	$a0: first number
#	$a1: second number
# Return:
#	$v0: ($a0/$a1)
# 	$v1: remainder of ($a0/$a1)
# Notes: converts numbers to unsigned then called unsigned division
#####################################################################	
div_logical:
	addi	$sp, $sp, -36
	sw   	$fp,  36($sp)
	sw   	$ra,  32($sp)
	sw   	$a0,  28($sp)
	sw   	$a1,  24($sp)
	sw	$s0,  20($sp)
	sw	$s1,  16($sp)
	sw	$s2,  12($sp)
	sw	$s3,   8($sp)
	addi 	$fp, $sp, 36
	
	li $s0, 31 #used to find last bit
	extract_nth_bit($s2, $a0, $s0)
	extract_nth_bit($s3, $a1, $s0)
	xor $s3, $s2, $s3	#Get the final sign bit of the result
	
	move $s0, $a0
	move $s1, $a1
	
	bgtz $s0, FIRSTPOSDIV	#check if 1st number is positive or negative
	move $a0, $s0
	jal twos_compliment	#make first number positive
	move $s0, $v0
	FIRSTPOSDIV:
		bgtz $s1, BOTHPOSDIV	#check if 2nd number is positive or negative
		move $a0, $s1
		jal twos_compliment	#make 2nd number positive
		move $s1, $v0
	BOTHPOSDIV:
		move $a0, $s0
		move $a1, $s1
		jal unsigned_division	#perform unsigned division
		move $s0, $v0
		move $s1, $v1
		beqz $s3, CHECKR	#Check if final result is positive or negative
		move $a0, $s0
		jal twos_compliment	#make final result negative
		move $s0, $v0
	CHECKR:
		beqz $s2, ENDDIVL	#check if remainder is positive or negative
		move $a0, $s1
		jal twos_compliment	#make remainder negative
		move $s1, $v0
	ENDDIVL:
		move $v0, $s0		#set $a0 / $a1
		move $v1, $s1		#set $a0 % $a1
		
	lw   	$fp, 36($sp)
	lw   	$ra, 32($sp)
	lw   	$a0, 28($sp)
	lw   	$a1, 24($sp)
	lw	$s0,  20($sp)
	lw	$s1,  16($sp)
	lw	$s2,  12($sp)
	lw	$s3,  8($sp)
	addi	$sp, $sp, 36
	jr 	$ra		
#####################################################################
# Implement au_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_normal:
	addi $sp, $sp, -24
	sw   $fp, 24($sp)
	sw   $ra, 20($sp)
	sw   $a0, 16($sp)
	sw   $a1, 12($sp)
	sw   $a2, 8($sp)
	addi $fp, $sp, 24
	#check for add, sub, mul, or div
	beq $a2, '+', ADDN
	beq $a2, '-', SUBN
	beq $a2, '*', MULN
	beq $a2, '/', DIVN
	ADDN:			#perform +
		jal add_normal
		j END
	SUBN:			#perform -
		jal sub_normal
		j END
	MULN:			#perform *
		jal mul_normal
		j END
	DIVN:			#perform /
		jal div_normal
		j END		
END:	
	lw   $fp, 24($sp)
	lw   $ra, 20($sp)
	lw   $a0, 16($sp)
	lw   $a1, 12($sp)
	lw   $a2,  8($sp)
	addi $sp, $sp, 24
	jr	$ra
#####################################################################
# Implement add_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
# Return:
#	$v0: ($a0+$a1)
# Notes: calls add
#####################################################################			
add_normal:
	addi $sp, $sp, -20
	sw   $fp, 20($sp)
	sw   $ra, 16($sp)
	sw   $a0, 12($sp)
	sw   $a1, 8($sp)
	addi $fp, $sp, 20

	add $v0, $a0, $a1	#add the numbers

	lw   $fp, 20($sp)
	lw   $ra, 16($sp)
	lw   $a0, 12($sp)
	lw   $a1, 8($sp)
	addi $sp, $sp, 20
	jr $ra
#####################################################################
# Implement au_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
# Return:
#	$v0: ($a0-$a1)
# Notes: calls sub
#####################################################################
sub_normal:
	addi $sp, $sp, -20
	sw   $fp, 20($sp)
	sw   $ra, 16($sp)
	sw   $a0, 12($sp)
	sw   $a1, 8($sp)
	addi $fp, $sp, 20

	sub $v0, $a0, $a1	#subtract the numbers

	lw   $fp, 20($sp)
	lw   $ra, 16($sp)
	lw   $a0, 12($sp)
	lw   $a1, 8($sp)
	addi $sp, $sp, 20
	jr $ra
#####################################################################
# Implement mul_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
# Return:
#	$v0:($a0*$a1):LO
# 	$v1: ($a0 * $a1):HI
# Notes: calls mult
#####################################################################
mul_normal:
	addi $sp, $sp, -20
	sw   $fp, 20($sp)
	sw   $ra, 16($sp)
	sw   $a0, 12($sp)
	sw   $a1, 8($sp)
	addi $fp, $sp, 20

	mult  $a0, $a1		#multiply the numbers
	mflo  $v0		#store the LO value
	mfhi  $v1		#store the HI value

	lw   $fp, 20($sp)
	lw   $ra, 16($sp)
	lw   $a0, 12($sp)
	lw   $a1, 8($sp)
	addi $sp, $sp, 20
	jr $ra
#####################################################################
# Implement div_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
# Return:
#	$v0:  ($a0 / $a1)
# 	$v1:  ($a0 % $a1)
# Notes: calls div
#####################################################################
div_normal:
	addi $sp, $sp, -20
	sw   $fp, 20($sp)
	sw   $ra, 16($sp)
	sw   $a0, 12($sp)
	sw   $a1, 8($sp)
	addi $fp, $sp, 20

	div   $a0, $a1		#divide the numbers
	mflo  $v0		#store the result
	mfhi  $v1		#store the remainder

	lw   $fp, 20($sp)
	lw   $ra, 16($sp)
	lw   $a0, 12($sp)
	lw   $a1, 8($sp)
	addi $sp, $sp, 20
	jr $ra
