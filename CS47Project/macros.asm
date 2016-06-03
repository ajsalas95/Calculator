#<------------------ MACRO DEFINITIONS ---------------------->#
        # Macro : print_str
        # Usage: print_str(<address of the string>)
        .macro print_str($arg)
	li	$v0, 4     # System call code for print_str  
	la	$a0, $arg   # Address of the string to print
	syscall            # Print the string        
	.end_macro
	
	# Macro : print_int
        # Usage: print_int(<val>)
        .macro print_int($arg)
	li 	$v0, 1     # System call code for print_int
	li	$a0, $arg  # Integer to print
	syscall            # Print the integer
	.end_macro
	
	# Macro : exit
        # Usage: exit
        .macro exit
	li 	$v0, 10 
	syscall
	.end_macro
	
	# Macro: read_int
	# Usage: read_int(<reg>)
	.macro read_int($arg)
	li	$v0,5	# Read intger
	syscall
	move	$arg, $v0 # move the data to target reg
	.end_macro
	
	# Macro: print_reg_int
	# Usage: print_reg_int(<reg>)
	.macro print_reg_int ($arg)
	li	$v0, 1		# print_int call
	move	$a0, $arg 	# move the source reg value to $a0
	syscall
	.end_macro
	
	# Macro: lwi
	# Usage: lwi (<reg>, <upper imm>, <lower imm>)
	.macro lwi ($reg, $ui, $li)
	lui $reg, $ui
	ori $reg, $reg, $li
	.end_macro
	
	# Macro: push
	# Usage: push (<reg>)
	.macro push($reg)
	sw	$reg, 0x0($sp)	# M[$sp] = R[reg]
	addi    $sp, $sp, -4	# R[sp] = R[sp] - 4
	.end_macro
	
	# Macro: push
	# Usage: push (<reg>)
	.macro pop($reg)
	addi    $sp, $sp, +4	# R[sp] = R[sp] + 4
	lw	$reg, 0x0($sp)	# M[$sp] = R[reg]
	.end_macro

	.macro push_var_value($varName)
	lw	$t0, $varName
	push($t0)
	.end_macro
	
	.macro push_var_address($varName)
	la	$t0, $varName
	push($t0)
	.end_macro

	.macro call_printf($format)
	la	$a0, $format
	jal	printf
	.end_macro
	
	.macro extract_nth_bit($regD, $regS, $regT) #gets the nth bit
	srlv $regD, $regS, $regT
	andi $regD, $regD, 1
	.end_macro 

	.macro insert_one_to_nth_bit($regD, $regS, $regT, $mask_reg) #inserts a one or zero to the nth bit
	addi	$mask_reg, $zero, 1
	sllv	$mask_reg, $mask_reg, $regS
	nor $mask_reg, $mask_reg, $zero
	and $regD, $regD, $mask_reg
	sllv $regT, $regT, $regS
	or $regD, $regT, $regD
	.end_macro 
	
	.macro read_char($char)	#reads a character from a string
	li $v0, 8
	la $a0, $char
	li $a1, 2
	syscall
	.end_macro 

