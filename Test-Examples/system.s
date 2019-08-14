	.text
	.file	"system.c"
# ---------------------------------------------
# memcpy
# ---------------------------------------------
	.globl	memcpy
memcpy:
	push	r5
	push	r4
	mov	r1, r3
	and	r3, 1, r3
	brne	.LBB0_5
	mov	r0, r3
	and	r3, 1, r3
	brne	.LBB0_5
	mov	-2, r3
	and	r2, r3, r4
	mov	0, r3
.LBB0_3:
	cmp	r3, r4
	bruge	.LBB0_8
	ld.w	[r1, r3], r5
	st.w	r5, [r0, r3]
	add	r3, 2, r3
	jmp	.LBB0_3
.LBB0_5:
	mov	0, r3
.LBB0_6:
	cmp	r2, r3
	breq	.LBB0_10
	ld.sb	[r1, r3], r4
	st.b	r4, [r0, r3]
	add	r3, 1, r3
	jmp	.LBB0_6
.LBB0_8:
	and	r2, 1, r2
	breq	.LBB0_10
	ld.sb	[r1, r3], r1
	st.b	r1, [r0, r3]
.LBB0_10:
	pop	r4
	pop	r5
	ret

# ---------------------------------------------
# __ashrhi3
# ---------------------------------------------
	.globl	__ashrhi3
__ashrhi3:
	cmp	r1, 15
	brne	.LBB1_2
	sextw	r0, r0
	jmp	.LBB1_5
.LBB1_2:
	bswap	r0, r2
	sext	r2, r2
	cmp	r1, 7
	selgt	r2, r0, r0
	and	r1, 7, r1
.LBB1_3:
	cmp	r1, 0
	breq	.LBB1_5
	sub	r1, 1, r1
	asr	r0, r0
	jmp	.LBB1_3
.LBB1_5:
	ret

# ---------------------------------------------
# __lshrhi3
# ---------------------------------------------
	.globl	__lshrhi3
__lshrhi3:
	cmp	r1, 15
	brne	.LBB2_2
	cmp	r0, 0
	setlt	r0
	jmp	.LBB2_5
.LBB2_2:
	bswap	r0, r2
	zext	r2, r2
	cmp	r1, 7
	selgt	r2, r0, r0
	and	r1, 7, r1
.LBB2_3:
	cmp	r1, 0
	breq	.LBB2_5
	sub	r1, 1, r1
	lsr	r0, r0
	jmp	.LBB2_3
.LBB2_5:
	ret

# ---------------------------------------------
# __ashlhi3
# ---------------------------------------------
	.globl	__ashlhi3
__ashlhi3:
	zext	r0, r2
	bswap	r2, r2
	cmp	r1, 7
	selgt	r2, r0, r0
	and	r1, 7, r1
.LBB3_1:
	cmp	r1, 0
	breq	.LBB3_3
	sub	r1, 1, r1
	lsl	r0, r0
	jmp	.LBB3_1
.LBB3_3:
	ret

# ---------------------------------------------
# __ashrsi3
# ---------------------------------------------
	.globl	__ashrsi3
__ashrsi3:
	push	r6
	push	r5
	push	r4
	sub	SP, 2, SP
	mov	r2, r6
	mov	r1, r4
	mov	r0, r5
	mov	r6, r0
	and	r0, 16, r0
	brne	.LBB4_3
	cmp	r6, 0
	breq	.LBB4_4
	mov	16, r0
	sub	r0, r6, r1
	mov	r4, r0
	jsr	__ashlhi3
	st.w	r0, [SP, 0]
	mov	r5, r0
	mov	r6, r1
	jsr	__lshrhi3
	ld.w	[SP, 0], r1
	or	r1, r0, r5
	mov	r4, r0
	mov	r6, r1
	jsr	__ashrhi3
	mov	r0, r4
	jmp	.LBB4_4
.LBB4_3:
	sub	r6, 16, r6
	mov	r4, r0
	mov	r6, r1
	jsr	__ashrhi3
	mov	r0, r5
	sextw	r4, r4
.LBB4_4:
	mov	r5, r0
	mov	r4, r1
	add	SP, 2, SP
	pop	r4
	pop	r5
	pop	r6
	ret

# ---------------------------------------------
# __lshrsi3
# ---------------------------------------------
	.globl	__lshrsi3
__lshrsi3:
	push	r6
	push	r5
	push	r4
	sub	SP, 2, SP
	mov	r2, r5
	mov	r1, r4
	mov	r0, r6
	mov	r5, r0
	and	r0, 16, r0
	brne	.LBB5_3
	cmp	r5, 0
	breq	.LBB5_5
	mov	16, r0
	sub	r0, r5, r1
	mov	r4, r0
	jsr	__ashlhi3
	st.w	r0, [SP, 0]
	mov	r6, r0
	mov	r5, r1
	jsr	__lshrhi3
	ld.w	[SP, 0], r1
	or	r1, r0, r6
	mov	r4, r0
	mov	r5, r1
	jsr	__lshrhi3
	mov	r0, r4
	mov	0, r0
	jmp	.LBB5_4
.LBB5_3:
	sub	r5, 16, r5
	mov	r4, r0
	mov	r5, r1
	jsr	__lshrhi3
	mov	r0, r6
	mov	0, r0
	mov	0, r4
.LBB5_4:
	or	r0, r6, r6
.LBB5_5:
	mov	r6, r0
	mov	r4, r1
	add	SP, 2, SP
	pop	r4
	pop	r5
	pop	r6
	ret

# ---------------------------------------------
# __ashlsi3
# ---------------------------------------------
	.globl	__ashlsi3
__ashlsi3:
	push	r6
	push	r5
	push	r4
	mov	r2, r5
	mov	r0, r4
	mov	r5, r0
	and	r0, 16, r0
	brne	.LBB6_3
	cmp	r5, 0
	breq	.LBB6_5
	mov	r1, r0
	mov	r5, r1
	jsr	__ashlhi3
	mov	r0, r6
	mov	16, r0
	sub	r0, r5, r1
	mov	r4, r0
	jsr	__lshrhi3
	or	r6, r0, r6
	mov	r4, r0
	mov	r5, r1
	jsr	__ashlhi3
	mov	r0, r4
	jmp	.LBB6_4
.LBB6_3:
	sub	r5, 16, r5
	mov	r4, r0
	mov	r5, r1
	jsr	__ashlhi3
	mov	r0, r6
	mov	0, r4
.LBB6_4:
	mov	0, r0
	or	r6, r0, r1
.LBB6_5:
	mov	r4, r0
	pop	r4
	pop	r5
	pop	r6
	ret

# ---------------------------------------------
# __mulhi3
# ---------------------------------------------
	.globl	__mulhi3
__mulhi3:
	cmp	r0, r1
	selugt	r1, r0, r2
	selugt	r0, r1, r1
	mov	0, r0
.LBB7_1:
	cmp	r2, 0
	breq	.LBB7_3
	lsr	r2, r3
	and	r2, 1, r2
	neg	r2, r2
	and	r2, r1, r2
	add	r2, r0, r0
	lsl	r1, r1
	mov	r3, r2
	jmp	.LBB7_1
.LBB7_3:
	ret

# ---------------------------------------------
# __udivhi3
# ---------------------------------------------
	.globl	__udivhi3
__udivhi3:
	push	r6
	push	r5
	push	r4
	mov	1, r3
.LBB8_1:
	cmp	r1, 0
	brlt	.LBB8_5
	cmp	r1, r0
	bruge	.LBB8_5
	cmp	r3, 0
	breq	.LBB8_5
	lsl	r3, r3
	lsl	r1, r1
	jmp	.LBB8_1
.LBB8_5:
	mov	0, r4
	mov	0, r2
.LBB8_6:
	cmp	r3, 0
	breq	.LBB8_8
	cmp	r0, r1
	selult	r4, r1, r5
	selult	r4, r3, r6
	or	r2, r6, r2
	sub	r0, r5, r0
	lsr	r1, r1
	lsr	r3, r3
	jmp	.LBB8_6
.LBB8_8:
	mov	r2, r0
	pop	r4
	pop	r5
	pop	r6
	ret

# ---------------------------------------------
# __umodhi3
# ---------------------------------------------
	.globl	__umodhi3
__umodhi3:
	mov	1, r2
.LBB9_1:
	cmp	r1, 0
	brlt	.LBB9_6
	cmp	r1, r0
	bruge	.LBB9_6
	cmp	r2, 0
	breq	.LBB9_6
	lsl	r2, r2
	lsl	r1, r1
	jmp	.LBB9_1
.LBB9_5:
	cmp	r0, r1
	mov	0, r3
	selult	r3, r1, r3
	sub	r0, r3, r0
	lsr	r1, r1
	lsr	r2, r2
.LBB9_6:
	cmp	r2, 0
	brne	.LBB9_5
	ret

# ---------------------------------------------
# __divhi3
# ---------------------------------------------
	.globl	__divhi3
__divhi3:
	push	r5
	push	r4
	mov	r1, r4
	mov	r0, r5
	sextw	r5, r0
	add	r5, r0, r1
	xor	r1, r0, r0
	sextw	r4, r1
	add	r4, r1, r2
	xor	r2, r1, r1
	jsr	__udivhi3
	xor	r4, r5, r1
	neg	r0, r2
	cmp	r1, -1
	selgt	r0, r2, r0
	pop	r4
	pop	r5
	ret

# ---------------------------------------------
# __modhi3
# ---------------------------------------------
	.globl	__modhi3
__modhi3:
	push	r4
	mov	r0, r4
	sextw	r4, r0
	add	r4, r0, r2
	xor	r2, r0, r0
	sextw	r1, r2
	add	r1, r2, r1
	xor	r1, r2, r1
	jsr	__umodhi3
	neg	r0, r1
	cmp	r4, -1
	selgt	r0, r1, r0
	pop	r4
	ret

# ---------------------------------------------
# __mulsi3
# ---------------------------------------------
	.globl	__mulsi3
__mulsi3:
	push	r6
	push	r5
	push	r4
	sub	SP, 4, SP
	mov	r1, r5
	cmp	r2, r0
	setuge	r1
	cmp	r3, r5
	setuge	r4
	cmp	r5, r3
	seleq	r1, r4, r1
	and	r1, 1, r1
	brne	.LBB12_2
	mov	r2, r1
	mov	r3, r4
	mov	r0, r2
	mov	r5, r3
	mov	r1, r0
	mov	r4, r5
.LBB12_2:
	mov	0, r1
	st.w	r1, [SP, 2]
	mov	0, r1
	st.w	r1, [SP, 0]
.LBB12_3:
	cmp	r5, 0
	breq	.LBB12_5
	lsr	r5, r1
	and	r5, 1, r5
	neg	r5, r5
	and	r5, r2, r4
	ld.w	[SP, 2], r6
	add	r4, r6, r6
	st.w	r6, [SP, 2]
	and	r5, r3, r4
	ld.w	[SP, 0], r5
	addc	r4, r5, r5
	st.w	r5, [SP, 0]
	lsl	r3, r3
	cmp	r2, 0
	setlt	r4
	or	r3, r4, r3
	lsl	r2, r2
	mov	r1, r5
	jmp	.LBB12_3
.LBB12_5:
	ld.w	[SP, 2], r6
	ld.w	[SP, 0], r1
.LBB12_6:
	cmp	r0, 0
	breq	.LBB12_8
	lsr	r0, r4
	and	r0, 1, r0
	neg	r0, r0
	and	r0, r2, r5
	add	r5, r6, r6
	and	r0, r3, r0
	addc	r0, r1, r1
	lsl	r3, r0
	cmp	r2, 0
	setlt	r3
	or	r0, r3, r3
	lsl	r2, r2
	mov	r4, r0
	jmp	.LBB12_6
.LBB12_8:
	mov	r6, r0
	add	SP, 4, SP
	pop	r4
	pop	r5
	pop	r6
	ret

# ---------------------------------------------
# __udivsi3
# ---------------------------------------------
	.globl	__udivsi3
__udivsi3:
	push	r6
	push	r5
	push	r4
	sub	SP, 16, SP
	mov	r2, r4
	st.w	r1, [SP, 14]
	st.w	r0, [SP, 12]
	mov	0, r2
	mov	1, r6
.LBB13_1:
	cmp	r3, 0
	brlt	.LBB13_5
	ld.w	[SP, 12], r0
	cmp	r4, r0
	setuge	r5
	ld.w	[SP, 14], r0
	cmp	r3, r0
	mov	r6, r0
	setuge	r6
	seleq	r5, r6, r5
	mov	r0, r6
	and	r5, 1, r5
	brne	.LBB13_5
	or	r6, r2, r5
	breq	.LBB13_5
	lsl	r2, r1
	cmp	r6, 0
	setlt	r5
	or	r1, r5, r2
	lsl	r3, r0
	cmp	r4, 0
	setlt	r5
	or	r0, r5, r3
	lsl	r6, r6
	lsl	r4, r4
	jmp	.LBB13_1
.LBB13_5:
	mov	r3, r1
	mov	0, r0
	st.w	r0, [SP, 8]
	mov	0, r0
	st.w	r0, [SP, 6]
.LBB13_6:
	mov	r6, r3
	or	r3, r2, r6
	breq	.LBB13_8
	ld.w	[SP, 12], r6
	cmp	r6, r4
	setult	r0
	st.w	r4, [SP, 4]
	ld.w	[SP, 14], r4
	cmp	r4, r1
	setult	r5
	seleq	r0, r5, r5
	cmp	r5, 0
	mov	0, r0
	selne	r0, r3, r5
	st.w	r5, [SP, 2]
	selne	r0, r2, r5
	st.w	r5, [SP, 0]
	st.w	r2, [SP, 10]
	selne	r0, r1, r5
	ld.w	[SP, 4], r2
	selne	r0, r2, r0
	sub	r6, r0, r6
	st.w	r6, [SP, 12]
	subc	r4, r5, r4
	st.w	r4, [SP, 14]
	ld.w	[SP, 6], r0
	ld.w	[SP, 0], r4
	or	r0, r4, r0
	st.w	r0, [SP, 6]
	ld.w	[SP, 8], r0
	ld.w	[SP, 2], r4
	or	r0, r4, r0
	st.w	r0, [SP, 8]
	zext	r1, r0
	bswap	r0, r0
	lsr	r2, r2
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	or	r2, r0, r4
	ld.w	[SP, 10], r0
	zext	r0, r0
	bswap	r0, r0
	lsr	r3, r3
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	lsl	r0, r0
	or	r3, r0, r6
	ld.w	[SP, 10], r2
	lsr	r1, r1
	lsr	r2, r2
	jmp	.LBB13_6
.LBB13_8:
	ld.w	[SP, 8], r0
	ld.w	[SP, 6], r1
	add	SP, 16, SP
	pop	r4
	pop	r5
	pop	r6
	ret

# ---------------------------------------------
# __umodsi3
# ---------------------------------------------
	.globl	__umodsi3
__umodsi3:
	push	r6
	push	r5
	push	r4
	sub	SP, 6, SP
	st.w	r1, [SP, 4]
	st.w	r0, [SP, 2]
	mov	0, r0
	mov	1, r5
.LBB14_1:
	cmp	r3, 0
	brlt	.LBB14_6
	ld.w	[SP, 2], r1
	cmp	r2, r1
	setuge	r6
	ld.w	[SP, 4], r4
	cmp	r3, r4
	setuge	r4
	seleq	r6, r4, r4
	and	r4, 1, r4
	brne	.LBB14_6
	or	r5, r0, r4
	breq	.LBB14_6
	lsl	r0, r1
	cmp	r5, 0
	setlt	r4
	or	r1, r4, r0
	lsl	r3, r3
	cmp	r2, 0
	setlt	r4
	or	r3, r4, r3
	lsl	r5, r5
	lsl	r2, r2
	jmp	.LBB14_1
.LBB14_5:
	st.w	r5, [SP, 0]
	mov	r0, r5
	ld.w	[SP, 2], r0
	cmp	r0, r2
	setult	r4
	ld.w	[SP, 4], r1
	cmp	r1, r3
	setult	r6
	seleq	r4, r6, r4
	cmp	r4, 0
	mov	0, r4
	selne	r4, r3, r6
	selne	r4, r2, r4
	sub	r0, r4, r0
	st.w	r0, [SP, 2]
	mov	r5, r0
	subc	r1, r6, r1
	st.w	r1, [SP, 4]
	zext	r3, r4
	bswap	r4, r4
	lsr	r2, r2
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	or	r2, r4, r2
	zext	r0, r4
	bswap	r4, r4
	ld.w	[SP, 0], r1
	lsr	r1, r5
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	lsl	r4, r4
	or	r5, r4, r5
	lsr	r3, r3
	lsr	r0, r0
.LBB14_6:
	or	r5, r0, r4
	brne	.LBB14_5
	ld.w	[SP, 2], r0
	ld.w	[SP, 4], r1
	add	SP, 6, SP
	pop	r4
	pop	r5
	pop	r6
	ret

# ---------------------------------------------
# __divsi3
# ---------------------------------------------
	.globl	__divsi3
__divsi3:
	push	r6
	push	r5
	push	r4
	sub	SP, 2, SP
	mov	r3, r4
	mov	r1, r5
	mov	0, r6
	sub	r6, r0, r1
	subc	r6, r5, r3
	cmp	r5, 0
	sellt	r1, r0, r0
	st.w	r0, [SP, 0]
	sellt	r3, r5, r1
	sub	r6, r2, r3
	subc	r6, r4, r0
	cmp	r4, 0
	sellt	r3, r2, r2
	sellt	r0, r4, r3
	ld.w	[SP, 0], r0
	jsr	__udivsi3
	xor	r4, r5, r2
	sub	r6, r0, r3
	subc	r6, r1, r4
	cmp	r2, -1
	selgt	r0, r3, r0
	selgt	r1, r4, r1
	add	SP, 2, SP
	pop	r4
	pop	r5
	pop	r6
	ret

# ---------------------------------------------
# __modsi3
# ---------------------------------------------
	.globl	__modsi3
__modsi3:
	push	r6
	push	r5
	push	r4
	mov	r1, r4
	mov	0, r5
	sub	r5, r2, r1
	subc	r5, r3, r6
	cmp	r3, 0
	sellt	r1, r2, r2
	sellt	r6, r3, r3
	sub	r5, r0, r1
	subc	r5, r4, r6
	cmp	r4, 0
	sellt	r1, r0, r0
	sellt	r6, r4, r1
	jsr	__umodsi3
	sub	r5, r0, r2
	subc	r5, r1, r3
	cmp	r4, -1
	selgt	r0, r2, r0
	selgt	r1, r3, r1
	pop	r4
	pop	r5
	pop	r6
	ret


