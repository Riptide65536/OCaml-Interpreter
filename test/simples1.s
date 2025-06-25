.globl main
.text
main:
	addi sp, sp, -8
	sw fp, 4(sp)
	sw ra, 0(sp)
	mv fp, sp
	addi sp, sp, -64
	li a0, 10
	sw a0, -4(fp)
	li a0, 20
	sw a0, -8(fp)
	lw a0, -4(fp)
	mv t0, a0
	lw a0, -8(fp)
	add a0, t0, a0
	sw a0, -12(fp)
	lw a0, -12(fp)
	mv t0, a0
	li a0, 25
	sgt a0, t0, a0
	beqz a0, else_0
	lw a0, -12(fp)
	j main_return
	j endif_1
else_0:
	li a0, 0
	j main_return
endif_1:
main_return:
	lw ra, 0(fp)
	lw fp, 4(fp)
	addi sp, fp, 8
	ret
test:
	addi sp, sp, -8
	sw fp, 4(sp)
	sw ra, 0(sp)
	mv fp, sp
	addi sp, sp, -64
	li a0, 0
	j test_return
test_return:
	lw ra, 0(fp)
	lw fp, 4(fp)
	addi sp, fp, 8
	ret
