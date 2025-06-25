.globl main
.text
fibonacci:
	addi sp, sp, -8
	sw fp, 4(sp)
	sw ra, 0(sp)
	mv fp, sp
	addi sp, sp, -64
	sw a0, -4(fp)
	lw a0, -4(fp)
	mv t0, a0
	li a0, 1
	sgt a0, t0, a0
	seqz a0, a0
	beqz a0, else_0
	lw a0, -4(fp)
	j fibonacci_return
	j endif_1
else_0:
endif_1:
	addi sp, sp, -4
	sw ra, 0(sp)
	lw a0, -4(fp)
	mv t0, a0
	li a0, 1
	sub a0, t0, a0
	call fibonacci
	lw ra, 0(sp)
	addi sp, sp, 4
	mv t0, a0
	addi sp, sp, -4
	sw ra, 0(sp)
	lw a0, -4(fp)
	mv t0, a0
	li a0, 2
	sub a0, t0, a0
	call fibonacci
	lw ra, 0(sp)
	addi sp, sp, 4
	add a0, t0, a0
	j fibonacci_return
fibonacci_return:
	lw ra, 0(fp)
	lw fp, 4(fp)
	addi sp, fp, 8
	ret
factorial:
	addi sp, sp, -8
	sw fp, 4(sp)
	sw ra, 0(sp)
	mv fp, sp
	addi sp, sp, -64
	sw a0, -4(fp)
	li a0, 1
	sw a0, -8(fp)
	li a0, 1
	sw a0, -12(fp)
while_start_0:
	lw a0, -12(fp)
	mv t0, a0
	lw a0, -4(fp)
	sgt a0, t0, a0
	seqz a0, a0
	beqz a0, while_end_1
	lw a0, -8(fp)
	mv t0, a0
	lw a0, -12(fp)
	mul a0, t0, a0
	sw a0, -8(fp)
	lw a0, -12(fp)
	mv t0, a0
	li a0, 1
	add a0, t0, a0
	sw a0, -12(fp)
	j while_start_0
while_end_1:
	lw a0, -8(fp)
	j factorial_return
factorial_return:
	lw ra, 0(fp)
	lw fp, 4(fp)
	addi sp, fp, 8
	ret
isPrime:
	addi sp, sp, -8
	sw fp, 4(sp)
	sw ra, 0(sp)
	mv fp, sp
	addi sp, sp, -64
	sw a0, -4(fp)
	lw a0, -4(fp)
	mv t0, a0
	li a0, 1
	sgt a0, t0, a0
	seqz a0, a0
	beqz a0, else_0
	li a0, 0
	j isPrime_return
	j endif_1
else_0:
endif_1:
	lw a0, -4(fp)
	mv t0, a0
	li a0, 3
	sgt a0, t0, a0
	seqz a0, a0
	beqz a0, else_2
	li a0, 1
	j isPrime_return
	j endif_3
else_2:
endif_3:
	lw a0, -4(fp)
	mv t0, a0
	li a0, 2
	rem a0, t0, a0
	mv t0, a0
	li a0, 0
	xor a0, t0, a0
	seqz a0, a0
	mv t0, a0
	lw a0, -4(fp)
	mv t0, a0
	li a0, 3
	rem a0, t0, a0
	mv t0, a0
	li a0, 0
	xor a0, t0, a0
	seqz a0, a0
	bnez t0, or_true_6
	bnez a0, or_true_6
	li a0, 0
	j or_end_7
or_true_6:
	li a0, 1
or_end_7:
	beqz a0, else_4
	li a0, 0
	j isPrime_return
	j endif_5
else_4:
endif_5:
	li a0, 5
	sw a0, -8(fp)
while_start_8:
	lw a0, -8(fp)
	mv t0, a0
	lw a0, -8(fp)
	mul a0, t0, a0
	mv t0, a0
	lw a0, -4(fp)
	sgt a0, t0, a0
	seqz a0, a0
	beqz a0, while_end_9
	lw a0, -4(fp)
	mv t0, a0
	lw a0, -8(fp)
	rem a0, t0, a0
	mv t0, a0
	li a0, 0
	xor a0, t0, a0
	seqz a0, a0
	mv t0, a0
	lw a0, -4(fp)
	mv t0, a0
	lw a0, -8(fp)
	mv t0, a0
	li a0, 2
	add a0, t0, a0
	rem a0, t0, a0
	mv t0, a0
	li a0, 0
	xor a0, t0, a0
	seqz a0, a0
	bnez t0, or_true_12
	bnez a0, or_true_12
	li a0, 0
	j or_end_13
or_true_12:
	li a0, 1
or_end_13:
	beqz a0, else_10
	li a0, 0
	j isPrime_return
	j endif_11
else_10:
endif_11:
	lw a0, -8(fp)
	mv t0, a0
	li a0, 6
	add a0, t0, a0
	sw a0, -8(fp)
	j while_start_8
while_end_9:
	li a0, 1
	j isPrime_return
isPrime_return:
	lw ra, 0(fp)
	lw fp, 4(fp)
	addi sp, fp, 8
	ret
main:
	addi sp, sp, -8
	sw fp, 4(sp)
	sw ra, 0(sp)
	mv fp, sp
	addi sp, sp, -64
	li a0, 2
	sw a0, -4(fp)
	li a0, 0
	sw a0, -8(fp)
	lw a0, -4(fp)
	mv t0, a0
	li a0, 1
	xor a0, t0, a0
	seqz a0, a0
	beqz a0, else_0
	addi sp, sp, -4
	sw ra, 0(sp)
	li a0, 8
	call fibonacci
	lw ra, 0(sp)
	addi sp, sp, 4
	sw a0, -8(fp)
	j endif_1
else_0:
	lw a0, -4(fp)
	mv t0, a0
	li a0, 2
	xor a0, t0, a0
	seqz a0, a0
	beqz a0, else_2
	addi sp, sp, -4
	sw ra, 0(sp)
	li a0, 5
	call factorial
	lw ra, 0(sp)
	addi sp, sp, 4
	sw a0, -8(fp)
	j endif_3
else_2:
	addi sp, sp, -4
	sw ra, 0(sp)
	li a0, 17
	call isPrime
	lw ra, 0(sp)
	addi sp, sp, 4
	sw a0, -8(fp)
endif_3:
endif_1:
	lw a0, -8(fp)
	j main_return
main_return:
	lw ra, 0(fp)
	lw fp, 4(fp)
	addi sp, fp, 8
	ret
