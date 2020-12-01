	.text
	.file	"systemio.c"
# ---------------------------------------------
# printstr
# ---------------------------------------------
	.globl	printstr
printstr:
	ld.sb	[r0, 0], r1
	cmp.eq	r1, 0
	brcc	.LBB0_3
	addx	r0, 1, r0
.LBB0_2:
	st.b	r1, [-1L]
	addx	r0, 1, r2
	ld.sb	[r0, 0], r1
	cmp.eq	r1, 0
	mov	r2, r0
	brncc	.LBB0_2
.LBB0_3:
	ret

# ---------------------------------------------
# printnum
# ---------------------------------------------
	.globl	printnum
printnum:
	addx	SP, -2, SP
	st.w	r4, [SP, 0]
	mov	0, r1
	mov	&.L__const.printnum.factors, r2
.LBB1_1:
	ld.w	[r2, r1], r4
	cmp.ult	r0, r4
	mov	48, r3
	brcc	.LBB1_4
	mov	48, r3
.LBB1_3:
	sub	r0, r4, r0
	cmp.uge	r0, r4
	addx	r3, 1, r3
	brcc	.LBB1_3
.LBB1_4:
	st.b	r3, [-1L]
	addx	r1, 1, r1
	cmp.eq	r1, 5
	brncc	.LBB1_1
	ld.w	[SP, 0], r4
	addx	SP, 2, SP
	ret

# ---------------------------------------------
# Global Data
# ---------------------------------------------
	.section	.rodata,"a",@progbits
	.p2align	1
.L__const.printnum.factors:
	.short	10000
	.short	1000
	.short	100
	.short	10
	.short	1


