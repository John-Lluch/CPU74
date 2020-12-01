	.text
	.file	"TestUnits.c"
# ---------------------------------------------
# test
# ---------------------------------------------
	.globl	test
test:
	call	@printstr
	ret

# ---------------------------------------------
# pass
# ---------------------------------------------
	.globl	pass
pass:
	mov	&.L.str, r0
	call	@printstr
	ret

# ---------------------------------------------
# fail
# ---------------------------------------------
	.globl	fail
fail:
	mov	&.L.str.1, r0
	call	@printstr
	ret

# ---------------------------------------------
# function
# ---------------------------------------------
	.globl	function
function:
	# InlineAsm Start
	
	mov r1, r0
	cmp.eq r1, r0
	brcc 3
	call @fail
	halt
	nop	#function should be called
	# InlineAsm End
	ret

# ---------------------------------------------
# main
# ---------------------------------------------
	.globl	main
main:
	mov	&.L.str.2, r0
	call	@test
	# InlineAsm Start
		#pre add cmp
	mov 1, r0
	cmp.eq r0, 1
	brcc 3
	call @fail
	halt
	nop	#function should be called
	# InlineAsm End
	call	@pass
	mov	&.L.str.3, r0
	call	@test
	# InlineAsm Start
		#pre call test
	mov 3, r1
	call @function
	cmp.eq r0, 3
	brcc 3
	call @fail
	halt
	nop
	# InlineAsm End
	call	@pass
	mov	&.L.str.4, r0
	call	@test
	# InlineAsm Start
		#short branch test
	mov 0, r2
	add r2, 5, r2	#set NE flag
	jmp .Lpsb_test
.Lpsb_bwok:
	mov 5, r3
	add r2, r3, r3
	brncc .Lpsb_forw
	call @fail
	halt
	nop	#branch should be taken
	sub r3, 1, r3	#forward landing zone
	sub r3, 1, r3
	sub r3, 1, r3
	sub r3, 1, r3
	sub r3, 1, r3
.Lpsb_forw:
	sub r3, 1, r3
	sub r3, 1, r3
	sub r3, 1, r3
	sub r3, 1, r3
	sub r3, 1, r3
	brcc .Lpsb_fwok
	call @fail
	halt
	nop	#branch should be taken
	sub r2, 1, r2	#backward landing zone
	sub r2, 1, r2
	sub r2, 1, r2
	sub r2, 1, r2
	sub r2, 1, r2
.Lpsb_back:
	sub r2, 1, r2
	sub r2, 1, r2
	sub r2, 1, r2
	sub r2, 1, r2
	sub r2, 1, r2
	brcc .Lpsb_bwok
	call @fail
	halt
	nop	#branch should be taken
.Lpsb_test:
	brncc .Lpsb_back
	call @fail
	halt
	nop	#Error: branch should be taken
.Lpsb_fwok:	#success
	# InlineAsm End
	call	@pass
	mov	&.L.str.5, r0
	call	@test
	# InlineAsm Start
		#branch address test
	mov 5, r0
	mov @.Lba0, r2
.Lba_loop:
	mov -1, r1
	add r2, r0, r3
	jmp r3
.Lba0:
	addx r1, 1, r1	#.Lba0+0
	addx r1, 1, r1	#.Lba0+1
	addx r1, 1, r1	#.Lba0+2
	addx r1, 1, r1	#.Lba0+3
	addx r1, 1, r1	#.Lba0+4
	addx r1, 1, r1	#.Lba0+5	#branch address should land here
	add r0, r1, r1
	sub r1, 5, r1
	brcc .LbaNext
	call @fail
	halt
	nop	#Error: branch should be taken
.LbaNext:
	sub r0, 1, r0
	brncc .Lba_loop
.Lba_end:
	# InlineAsm End
	call	@pass
	mov	&.L.str.6, r0
	call	@test
	# InlineAsm Start
	
	mov 3, r1
	mov @function, r0
	call r0
	cmp.eq r0, 3
	brcc 3
	call @fail
	halt
	nop
	# InlineAsm End
	call	@pass
	mov	&.L.str.7, r0
	call	@test
	# InlineAsm Start
	
	mov 1, r1
	mov 1, r2
	cmp.eq r1, r2
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ne r1, r2
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.uge r1, r2
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ult r1, r2
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ge r1, r2
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.lt r1, r2
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ugt r1, r2
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.gt r1, r2
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	sub r1, r2, r3
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	add r1, r2, r3
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r1, 1
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ne r1, 1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.uge r1, 1
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ult r1, 1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ge r1, 1
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.lt r1, 1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ugt r1, 1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.gt r1, 1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	sub r1, 1, r1
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	add r2, 1, r2
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	mov 1, r4
	mov -1, r5
	cmp.eq r4, r5
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ne r4, r5
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.uge r4, r5
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ult r4, r5
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ge r4, r5
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.lt r4, r5
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ugt r4, r5
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.gt r4, r5
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	sub r4, r5, r3
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	add r4, r5, r3
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r4, -1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ne r4, -1
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.uge r4, -1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ult r4, -1
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ge r4, -1
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.lt r4, -1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ugt r4, -1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.gt r4, -1
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	add r5, 1, r5	#should be 0
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	sub r5, 1, r5	#should be -1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	sub r5, -1, r5	#should be 0
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	add r5, -1, r5	#should be -1
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r5, -1
	brcc 3
	call @fail
	halt
	nop
	# InlineAsm End
	call	@pass
	mov	&.L.str.8, r0
	call	@test
	# InlineAsm Start
	
	mov 1, r1
	mov 1, r2
	mov 1, r3
	mov 1, r4
	cmp.eq r1, r3	#low word
	cmpc.eq r2, r4	#high word
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ne r1, r3
	cmpc.ne r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.uge r1, r3
	cmpc.uge r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ult r1, r3
	cmpc.ult r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ge r1, r3
	cmpc.ge r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.lt r1, r3
	cmpc.lt r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ugt r1, r3
	cmpc.ugt r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.gt r1, r3
	cmpc.gt r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	sub r1, r3, r5
	subc r2, r4, r6
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	add r1, r3, r5
	addc r2, r4, r6
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	mov 1, r1
	mov 1, r2
	mov 0, r3
	mov 1, r4
	cmp.eq r1, r3	#low word
	cmpc.eq r2, r4	#high word
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ne r1, r3
	cmpc.ne r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.uge r1, r3
	cmpc.uge r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ult r1, r3
	cmpc.ult r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ge r1, r3
	cmpc.ge r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.lt r1, r3
	cmpc.lt r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ugt r1, r3
	cmpc.ugt r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.gt r1, r3
	cmpc.gt r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	sub r1, r3, r5
	subc r2, r4, r6
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	add r1, r3, r5
	addc r2, r4, r6
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	mov 1, r1
	mov 1, r2
	mov 0, r3
	mov -1, r4
	cmp.eq r1, r3	#low word
	cmpc.eq r2, r4	#high word
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ne r1, r3
	cmpc.ne r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.uge r1, r3
	cmpc.uge r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ult r1, r3
	cmpc.ult r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.ge r1, r3
	cmpc.ge r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.lt r1, r3
	cmpc.lt r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.ugt r1, r3
	cmpc.ugt r2, r4
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.gt r1, r3
	cmpc.gt r2, r4
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	sub r1, r3, r5
	subc r2, r4, r6
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	add r1, r3, r5
	addc r2, r4, r6
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	# InlineAsm End
	call	@pass
	mov	&.L.str.9, r0
	call	@test
	# InlineAsm Start
	
	mov 127, r3	#this should be extended to 0x007F
	cmp.eq r3, 127
	brcc 3
	call @fail
	halt
	nop	#this should be prefixed to 0x007F
	mov -128, r2	#this should be extended to 0xFF80
	cmp.eq r2, -128
	brcc 3
	call @fail
	halt
	nop	#this should be prefixed to 0xFF80
	mov 128, r1	#this should be prefixed to 0x0080
	cmp.eq r1, 128
	brcc 3
	call @fail
	halt
	nop	#this should be prefixed to 0x0080
	mov 15, r6	#this should be extended to 0x000F
	cmp.eq r6, 15
	brcc 3
	call @fail
	halt
	nop	#this should be extended to 0x000F
	mov -16, r5	#this should be extended to 0xFFF0
	cmp.eq r5, -16
	brcc 3
	call @fail
	halt
	nop	#this should be extended to 0xFFF0
	mov 16, r4	#this should be extended to 0x000F
	cmp.eq r4, 16
	brcc 3
	call @fail
	halt
	nop	#this should be prefixed to 0x000F
	# InlineAsm End
	call	@pass
	mov	&.L.str.10, r0
	call	@test
	# InlineAsm Start
	
	mov 0xAA55, r0
	mov 0x55AA, r7
	asrb r0, r1
	cmp.eq r1, 0xFFAA
	brcc 3
	call @fail
	halt
	nop
	asrb r7, r1
	cmp.eq r1, 0x0055
	brcc 3
	call @fail
	halt
	nop
	lsrb r0, r1
	cmp.eq r1, 0x00AA
	brcc 3
	call @fail
	halt
	nop
	lsrb r7, r1
	cmp.eq r1, 0x0055
	brcc 3
	call @fail
	halt
	nop
	lslb r0, r1
	cmp.eq r1, 0x5500
	brcc 3
	call @fail
	halt
	nop
	lslb r7, r1
	cmp.eq r1, 0xAA00
	brcc 3
	call @fail
	halt
	nop
	sext r0, r1
	cmp.eq r1, 0x0055
	brcc 3
	call @fail
	halt
	nop
	sext r7, r1
	cmp.eq r1, 0xFFAA
	brcc 3
	call @fail
	halt
	nop
	zext r0, r1
	cmp.eq r1, 0x0055
	brcc 3
	call @fail
	halt
	nop
	zext r7, r1
	cmp.eq r1, 0x00AA
	brcc 3
	call @fail
	halt
	nop
	sextw r0, r1
	cmp.eq r1, 0xffff
	brcc 3
	call @fail
	halt
	nop
	sextw r7, r1
	cmp.eq r1, 0
	brcc 3
	call @fail
	halt
	nop
	# InlineAsm End
	call	@pass
	mov	&.L.str.11, r0
	call	@test
	# InlineAsm Start
	
	mov 0x55AA, r0
	mov 0xAA55, r2	#shift left
	add r0, r0, r1
	cmp.eq r1, 0xAB54
	brcc 3
	call @fail
	halt
	nop
	add r2, r2, r3	#this produces 0x54AA + carry
	cmp.eq r3, 0x54AA
	brcc 3
	call @fail
	halt
	nop
	add r0, r0, r1
	addc r2, r2, r3	#carry should not apply
	cmp.eq r3, 0x54AA
	brcc 3
	call @fail
	halt
	nop
	add r2, r2, r3	#this produces 0x54AA + carry
	addc r3, r3, r3	#this consumes carry and produces 0xA955
	cmp.eq r3, 0xA955
	brcc 3
	call @fail
	halt
	nop
	add r2, r2, r3	#this produces 0x54AA + carry
	addc r2, r2, r3	#this consumes carry and procudes 0x54AB + carry
	addc r3, r3, r3
	cmp.eq r3, 0xA957
	brcc 3
	call @fail
	halt
	nop	#shift right
	lsr r0, r1
	cmp.eq r1, 0x2AD5
	brcc 3
	call @fail
	halt
	nop
	lsr r2, r3	#this produces 0x552A + carry
	cmp.eq r3, 0x552A
	brcc 3
	call @fail
	halt
	nop
	lsr r0, r1
	lsrc r2, r3	#carry should not apply
	cmp.eq r3, 0x552A
	brcc 3
	call @fail
	halt
	nop
	lsr r2, r3	#this produces 0x552A + carry
	lsrc r3, r3	#this consumes carry and produces 0xAA95
	cmp.eq r3, 0xAA95
	brcc 3
	call @fail
	halt
	nop
	lsr r2, r3	#this produces 0x552A + carry
	lsrc r2, r3	#this consumes carry and procudes 0xD52A + carry
	lsrc r3, r3
	cmp.eq r3, 0xEA95
	brcc 3
	call @fail
	halt
	nop	#arithmetic shift right
	asr r0, r1
	cmp.eq r1, 0x2AD5
	brcc 3
	call @fail
	halt
	nop
	asr r2, r3	#this produces carry
	cmp.eq r3, 0xD52A
	brcc 3
	call @fail
	halt
	nop
	asr r2, r3	#this produces carry, but should not affect asr
	asr r0, r1	#this should still produce 0x2AD5
	cmp.eq r1, 0x2AD5
	brcc 3
	call @fail
	halt
	nop
	asr r2, r3	#this produces carry
	lsrc r3, r3	#this consumes carry and produces 0xAA95
	cmp.eq r3, 0xEA95
	brcc 3
	call @fail
	halt
	nop
	asr r0, r1	#this does not produce carry
	lsrc r2, r3
	cmp.eq r3, 0x552A
	brcc 3
	call @fail
	halt
	nop	#carry should not apply
	# InlineAsm End
	call	@pass
	mov	&.L.str.12, r0
	call	@test
	# InlineAsm Start
	
	mov 0x55AA, r4
	mov 0x8134, r5
	mov 0xFF00, r6
	mov 0xABCD, r7	#save stack pointer
	addx SP, 0, r0	#save stack pointer
	addx SP, -8, SP	#word store
	st.w  r4, [SP, 6]	#push words
	st.w  r5, [SP, 4]
	st.w  r6, [SP, 2]
	st.w  r7, [SP, 0]	#load word test, retrieve in reverse register order
	ld.w [SP, 6], r7
	cmp.eq r7, 0x55AA
	brcc 3
	call @fail
	halt
	nop
	ld.w [SP, 4], r6
	cmp.eq r6, 0x8134
	brcc 3
	call @fail
	halt
	nop
	ld.w [SP, 2], r5
	cmp.eq r5, 0xFF00
	brcc 3
	call @fail
	halt
	nop
	ld.w [SP, 0], r4
	cmp.eq r4, 0xABCD
	brcc 3
	call @fail
	halt
	nop	#efective address test
	addx SP, 6, r1
	ld.w [r1, 0], r1
	cmp.eq r1, r7
	brcc 3
	call @fail
	halt
	nop
	addx SP, 6, r1
	ld.w [r1, -6], r1
	cmp.eq r1, r4
	brcc 3
	call @fail
	halt
	nop	#load byte test
	ld.sb [SP, 6], r1
	cmp.eq r1, 0xFFAA
	brcc 3
	call @fail
	halt
	nop	#sign extended 0xAA
	ld.sb [SP, 7], r1
	cmp.eq r1, 0x0055
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x55
	ld.sb [SP, 5], r1
	cmp.eq r1, 0xFF81
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x81
	ld.sb [SP, 4], r1
	cmp.eq r1, 0x0034
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x34
	ld.sb [SP, 2], r1
	cmp.eq r1, 0x0000
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x00
	ld.sb [SP, 3], r1
	cmp.eq r1, 0xFFFF
	brcc 3
	call @fail
	halt
	nop	#sign extended 0xFF	#byte store
	mov 0x22, r1
	st.b  r1, [SP, 7]	#push bytes
	mov 0xDD, r1
	st.b  r1, [SP, 4]
	mov 0x77, r1
	st.b  r1, [SP, 3]
	mov 0x99, r1
	st.b  r1, [SP, 0]	#load test
	ld.w [SP, 0], r1
	cmp.eq r1, 0xAB99
	brcc 3
	call @fail
	halt
	nop
	ld.w [SP, 2], r1
	cmp.eq r1, 0x7700
	brcc 3
	call @fail
	halt
	nop
	ld.w [SP, 4], r1
	cmp.eq r1, 0x81DD
	brcc 3
	call @fail
	halt
	nop
	ld.w [SP, 6], r1
	cmp.eq r1, 0x22AA
	brcc 3
	call @fail
	halt
	nop	#long stack frame test
	addx SP, -258, SP
	ld.w [SP, 264], r2
	cmp.eq r2, 0x22AA
	brcc 3
	call @fail
	halt
	nop
	ld.sb [SP, 264], r2
	cmp.eq r2, 0xFFAA
	brcc 3
	call @fail
	halt
	nop
	ld.sb [SP, 265], r2
	addx SP, 258, SP	#this should not modify flags
	cmp.eq r2, 0x0022
	brcc 3
	call @fail
	halt
	nop	#efective frame address test
	addx SP, 44, r1
	sub r1, 44, r1
	mov r1, SP
	addx SP, 8, SP
	addx SP, 0, r1
	cmp.eq r0, r1
	brcc 3
	call @fail
	halt
	nop	#check stack pointer
	# InlineAsm End
	call	@pass
	mov	&.L.str.13, r0
	call	@test
	# InlineAsm Start
	
	mov &loadStoreOffset_mem, r3
	mov 0x55AA, r4
	mov 0x8134, r5
	mov 0xFF00, r6
	mov 0xABCD, r7	#word store
	st.w  r4, [r3, 6]	#store words
	st.w  r5, [r3, 4]
	st.w  r6, [r3, 2]
	st.w  r7, [r3, 0]	#load word test, retrieve in reverse register order
	ld.w [r3, 6], r7
	cmp.eq r7, 0x55AA
	brcc 3
	call @fail
	halt
	nop
	ld.w [r3, 4], r6
	cmp.eq r6, 0x8134
	brcc 3
	call @fail
	halt
	nop
	ld.w [r3, 2], r5
	cmp.eq r5, 0xFF00
	brcc 3
	call @fail
	halt
	nop
	ld.w [r3, 0], r4
	cmp.eq r4, 0xABCD
	brcc 3
	call @fail
	halt
	nop	#load byte test
	ld.sb [r3, 6], r1
	cmp.eq r1, 0xFFAA
	brcc 3
	call @fail
	halt
	nop	#sign extended 0xAA
	ld.sb [r3, 7], r1
	cmp.eq r1, 0x0055
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x55
	ld.sb [r3, 5], r1
	cmp.eq r1, 0xFF81
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x81
	ld.sb [r3, 4], r1
	cmp.eq r1, 0x0034
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x34
	ld.sb [r3, 2], r1
	cmp.eq r1, 0x0000
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x00
	ld.sb [r3, 3], r1
	cmp.eq r1, 0xFFFF
	brcc 3
	call @fail
	halt
	nop	#sign extended 0xFF	#byte store
	mov 0x22, r1
	st.b  r1, [r3, 7]	#store bytes
	mov 0xDD, r1
	st.b  r1, [r3, 4]
	mov 0x77, r1
	st.b  r1, [r3, 3]
	mov 0x99, r1
	st.b  r1, [r3, 0]	#mixed load test
	ld.w [r3, 0], r1
	cmp.eq r1, 0xAB99
	brcc 3
	call @fail
	halt
	nop
	ld.w [r3, 2], r1
	cmp.eq r1, 0x7700
	brcc 3
	call @fail
	halt
	nop
	ld.w [r3, 4], r1
	cmp.eq r1, 0x81DD
	brcc 3
	call @fail
	halt
	nop
	ld.w [r3, 6], r1
	cmp.eq r1, 0x22AA
	brcc 3
	call @fail
	halt
	nop	#long word load/store test
	st.w r7, [r3, 62]
	ld.w [r3, 62], r2
	cmp.eq r2, r7
	brcc 3
	call @fail
	halt
	nop
	st.w r6, [r3, 64]
	ld.w [r3, 64], r2
	cmp.eq r2, r6
	brcc 3
	call @fail
	halt
	nop	#long word load/store test (2)
	st.w r4, [r3, 104]
	ld.w [r3, 104], r2
	cmp.eq r2, r4
	brcc 3
	call @fail
	halt
	nop
	addx r3, 104, r2
	ld.w [r2, 0], r2
	cmp.eq r2, r4
	brcc 3
	call @fail
	halt
	nop	#long mixed byte load/store test
	st.b r7, [r3, 32]	#this should be 0xAA
	ld.sb [r3, 32], r2
	sext r7, r1
	cmp.eq r1, r2
	brcc 3
	call @fail
	halt
	nop
	st.b r6, [r3, 33]	#this should be 0x34
	ld.sb [r3, 33], r2
	sext r6, r1
	cmp.eq r1, r2
	brcc 3
	call @fail
	halt
	nop
	ld.w [r3, 32], r1
	cmp.eq r1, 0x34AA
	brcc 3
	call @fail
	halt
	nop	#long mixed byte load/store test (2)
	st.b r7, [r3, 104]	#this should be 0xAA
	ld.sb [r3, 104], r2
	sext r7, r1
	cmp.eq r1, r2
	brcc 3
	call @fail
	halt
	nop
	st.b r6, [r3, 105]	#this should be 0x34
	ld.sb [r3, 105], r2
	sext r6, r1
	cmp.eq r1, r2
	brcc 3
	call @fail
	halt
	nop
	ld.w [r3, 104], r1
	cmp.eq r1, 0x34AA
	brcc 3
	call @fail
	halt
	nop
	addx r3, 104, r2
	ld.w [r2, 0], r1
	cmp.eq r1, 0x34AA
	brcc 3
	call @fail
	halt
	nop	#consistency check
	cmp.eq r3, &loadStoreOffset_mem
	brcc 3
	call @fail
	halt
	nop	#r3 should still be the same
	# InlineAsm End
	call	@pass
	mov	&.L.str.14, r0
	call	@test
	# InlineAsm Start
		#store word
	mov  0, r1
	mov  &loadStoreIndex_mem, r0
.Llsi_1:
	mov  r1, r2
	add  r2, 0x55FA, r2
	st.w  r2, [r0, r1]
	addx  r1, 1, r1
	cmp.eq  r1, 8
	brncc  .Llsi_1	#load word
	mov  0, r1
.Llsi_3:
	ld.w  [r0, r1], r2
	mov  r1, r3
	add  r3, 0x55FA, r3
	cmp.eq r3, r2
	brcc 3
	call @fail
	halt
	nop
	addx  r1, 1, r1
	cmp.eq  r1, 8
	brncc  .Llsi_3	#store byte
	mov  0, r1
.Llsi_7:
	mov  r1, r2
	add  r2, 0x7C, r2
	st.b  r2, [r1, r0]
	addx  r1, 1, r1
	cmp.eq  r1, 16
	brncc  .Llsi_7	#laod signed byte	#initial value is chosen so that a sign change happens along the loop
	mov  0, r1
.Llsi_9:
	ld.sb  [r1, r0], r2
	mov  r1, r3
	add  r3, 0x7C, r3
	sext  r3, r3
	cmp.eq r2, r3
	brcc 3
	call @fail
	halt
	nop
	addx  r1, 1, r1
	cmp.eq  r1, 16
	brncc  .Llsi_9	#load unsigned byte
	 mov  0, r1
.Llsi_13:
	ld.zb  [r1, r0], r2
	mov  r1, r3
	add  r3, 0x7C, r3
	zext  r3, r3
	cmp.eq r2, r3
	brcc 3
	call @fail
	halt
	nop
	addx  r1, 1, r1
	cmp.eq  r1, 16L
	brncc  .Llsi_13	#load mixed
	mov  0, r1
	lsr  r0, r0
.Llsi_17:
	ld.w  [r1, r0], r2
	mov  r1, r3
	add  r3, 0x7C, r3
	zext  r2, r4
	lsrb  r2, r2
	cmp.eq r3, r4
	brcc 3
	call @fail
	halt
	nop
	mov  r1, r3
	add  r3, 0x7D, r3
	cmp.eq r3, r2
	brcc 3
	call @fail
	halt
	nop
	addx  r1, 2, r1
	cmp.ugt  r1, 15
	brncc  .Llsi_17
	# InlineAsm End
	call	@pass
	mov	&.L.str.15, r0
	call	@test
	# InlineAsm Start
	
	mov 0x55AA, r4
	mov 0x8134, r5
	mov 0xFF00, r6
	mov 0xABCD, r7	#word store
	st.w  r4, [&dmem6]	#store words
	st.w  r5, [&dmem4]
	st.w  r6, [&dmem2]
	st.w  r7, [&dmem0]	#load word test, retrieve in reverse register order
	ld.w [&dmem6], r7
	cmp.eq r7, 0x55AA
	brcc 3
	call @fail
	halt
	nop
	ld.w [&dmem4], r6
	cmp.eq r6, 0x8134
	brcc 3
	call @fail
	halt
	nop
	ld.w [&dmem2], r5
	cmp.eq r5, 0xFF00
	brcc 3
	call @fail
	halt
	nop
	ld.w [&dmem0], r4
	cmp.eq r4, 0xABCD
	brcc 3
	call @fail
	halt
	nop	#load byte test
	ld.sb [&dmem6], r1
	cmp.eq r1, 0xFFAA
	brcc 3
	call @fail
	halt
	nop	#sign extended 0xAA
	ld.sb [&dmem6+1], r1
	cmp.eq r1, 0x0055
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x55
	ld.sb [&dmem4+1], r1
	cmp.eq r1, 0xFF81
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x81
	ld.sb [&dmem4], r1
	cmp.eq r1, 0x0034
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x34
	ld.sb [&dmem2], r1
	cmp.eq r1, 0x0000
	brcc 3
	call @fail
	halt
	nop	#sign extended 0x00
	ld.sb [&dmem2+1], r1
	cmp.eq r1, 0xFFFF
	brcc 3
	call @fail
	halt
	nop	#sign extended 0xFF	#byte store
	mov 0x22, r1
	st.b  r1, [&dmem6+1]	#store bytes
	mov 0xDD, r1
	st.b  r1, [&dmem4]
	mov 0x77, r1
	st.b  r1, [&dmem2+1]
	mov 0x99, r1
	st.b  r1, [&dmem0]	#mixed load test
	ld.w [&dmem0], r1
	cmp.eq r1, 0xAB99
	brcc 3
	call @fail
	halt
	nop
	ld.w [&dmem2], r1
	cmp.eq r1, 0x7700
	brcc 3
	call @fail
	halt
	nop
	ld.w [&dmem4], r1
	cmp.eq r1, 0x81DD
	brcc 3
	call @fail
	halt
	nop
	ld.w [&dmem6], r1
	cmp.eq r1, 0x22AA
	brcc 3
	call @fail
	halt
	nop	#long word load/store test
	st.w r7, [&dmem0+512]
	ld.w [&dmem0+512], r2
	cmp.eq r2, r7
	brcc 3
	call @fail
	halt
	nop	#long byte load/store test
	st.b r7, [&dmem0+256]	#this should be 0xAA
	ld.sb [&dmem0+256], r2
	sext r7, r1
	cmp.eq r1, r2
	brcc 3
	call @fail
	halt
	nop
	st.b r6, [&dmem0+257]	#this should be 0x34
	ld.sb [&dmem0+257], r2
	sext r6, r1
	cmp.eq r1, r2
	brcc 3
	call @fail
	halt
	nop
	ld.w [&dmem0+256], r1
	cmp.eq r1, 0x34AA
	brcc 3
	call @fail
	halt
	nop
.Llsa_end:
	# InlineAsm End
	call	@pass
	mov	&.L.str.16, r0
	call	@test
	# InlineAsm Start
	
	mov 0, r0
	mov 1, r1
	mov 2, r2
	mov 3, r3
	cmp.gt r1, r0
	selcc r2, r3, r4
	selcc 0, r3, r5
	selcc r2, 0, r6
	setcc r7
	cmp.eq r4, 2
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r5, 0
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r6, 2
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r7, 1
	brcc 3
	call @fail
	halt
	nop
	cmp.gt r0, r1
	selcc r2, r3, r4
	selcc 0, r3, r5
	selcc r2, 0, r6
	setcc r7
	cmp.eq r4, 3
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r5, 3
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r6, 0
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r7, 0
	brcc 3
	call @fail
	halt
	nop
	# InlineAsm End
	call	@pass
	mov	&.L.str.17, r0
	call	@test
	# InlineAsm Start
	
.def cnt = r2
.def a = r0
.def b = r1
	mov 0, cnt
	mov 0, a
.Lasa_outer:
	mov 0, b
.Lasa_inner:
	add a, b, r3
	cmp.eq cnt, r3
	brcc 3
	call @fail
	halt
	nop
	addx b, 1, b
	addx cnt, 1, cnt
	cmp.lt b, 16
	brcc .Lasa_inner
	addx a, 1, a
	sub cnt, 15, cnt
	cmp.lt a, 16
	brcc .Lasa_outer
	mov 0, cnt
	mov 15, a
.Lass_outer:
	mov 15, b
.Lass_inner:
	sub a, b, r3
	cmp.eq cnt, r3
	brcc 3
	call @fail
	halt
	nop
	sub b, 1, b
	addx cnt, 1, cnt
	cmp.ge b, 0
	brcc .Lass_inner
	sub a, 1, a
	sub cnt, 17, cnt
	cmp.ge a, 16
	brcc .Lass_outer
	mov -15, cnt
	mov 15, b
.Lasn_inner:
	neg b, r3
	cmp.eq cnt, r3
	brcc 3
	call @fail
	halt
	nop
	sub b, 1, b
	addx cnt, 1, cnt
	cmp.ge b, 0
	brcc .Lasn_inner
	# InlineAsm End
	call	@pass
	mov	&.L.str.18, r0
	call	@test
	# InlineAsm Start
	
.def cntlo = r4
.def cnthi = r5
.def al = r0
.def ah = r1
.def bl = r2
.def bh = r3
	mov 0, r6
	mov 0xFFFA, cntlo
	mov 0x0000, cnthi
	mov 0xFFFA, al
	mov 0x0000, ah
.Lasa32_outer:
	mov 0, bl
	mov 0, bh
.Lasa32_inner:
	add al, bl, r6
	addc ah, bh, r7
	cmp.eq cntlo, r6
	cmpc.eq cnthi, r7
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	add bl, 1, bl
	mov 0, r6
	addc bh, r6, bh
	add cntlo, 1, cntlo
	addc cnthi, r6, cnthi
	cmp.lt bl, 16
	cmpc.lt bh, 0
	brcc .Lasa32_inner
	add al, 1, al
	addc ah, r6, ah
	sub cntlo, 15, cntlo
	subc cnthi, r6, cnthi
	cmp.lt al, 0x000A
	cmpc.lt ah, 0x0001
	brcc .Lasa32_outer
	mov 0, r6
	mov 0xFFFA, cntlo
	mov 0x0000, cnthi
	mov 0x0009, al
	mov 0x0001, ah
.Lass32_outer:
	mov 15, bl
	mov 0, bh
.Lass32_inner:
	sub al, bl, r6
	subc ah, bh, r7
	cmp.eq cntlo, r6
	cmpc.eq cnthi, r7
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	sub bl, 1, bl
	mov 0, r6
	subc bh, r6, bh
	add cntlo, 1, cntlo
	addc cnthi, r6, cnthi
	cmp.ge bl, 0
	cmpc.ge bh, 0
	brcc .Lass32_inner
	sub al, 1, al
	subc ah, r6, ah
	sub cntlo, 17, cntlo
	subc cnthi, r6, cnthi
	cmp.ge al, 0xFFFA
	cmpc.ge ah, 0x0000
	brcc .Lass32_outer
	# InlineAsm End
	call	@pass
	mov	&.L.str.19, r0
	call	@test
	# InlineAsm Start
		#test patterns for AND
	mov 0x0F0F, r0
	mov 0xFFFF, r1
	mov 0x7F7F, r2
	mov 0x8080, r3
	mov 0xF0F0, r4
	mov 0xFFFF, r5
	mov 0xFFFF, r6
	mov 0xFFFF, r7
	and r0, r4, r0
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x0000
	brcc 3
	call @fail
	halt
	nop
	and r1, r5, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0xFFFF
	brcc 3
	call @fail
	halt
	nop
	and r2, r6, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x7F7F
	brcc 3
	call @fail
	halt
	nop
	and r3, r7, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x8080
	brcc 3
	call @fail
	halt
	nop
	mov 0x0F0F, r0
	and r0, 0xF0F0, r0
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x0000
	brcc 3
	call @fail
	halt
	nop
	and r1, -1, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0xFFFF
	brcc 3
	call @fail
	halt
	nop
	and r2, -1, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x7F7F
	brcc 3
	call @fail
	halt
	nop
	and r3, -1, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x8080
	brcc 3
	call @fail
	halt
	nop
	and r1, 0, r0
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0
	brcc 3
	call @fail
	halt
	nop	#test patterns for OR
	mov 0x0000, r0
	mov 0x1F1F, r1
	mov 0x7171, r2
	mov 0x8080, r3
	mov 0x0000, r4
	mov 0xF1F1, r5
	mov 0x1F1F, r6
	mov 0x0000, r7
	or r0, r4, r0
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x0000
	brcc 3
	call @fail
	halt
	nop
	or r1, r5, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0xFFFF
	brcc 3
	call @fail
	halt
	nop
	or r2, r6, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x7F7F
	brcc 3
	call @fail
	halt
	nop
	or r3, r7, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x8080
	brcc 3
	call @fail
	halt
	nop	#test patterns for XOR
	mov 0xFFFF, r0
	mov 0x0F0F, r1
	mov 0x8F8F, r2
	mov 0x8F8F, r3
	mov 0xFFFF, r4
	mov 0xF0F0, r5
	mov 0xF0F0, r6
	mov 0x0F0F, r7
	xor r0, r4, r0
	brncc 1
	brcc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x0000
	brcc 3
	call @fail
	halt
	nop
	xor r1, r5, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0xFFFF
	brcc 3
	call @fail
	halt
	nop
	xor r2, r6, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x7F7F
	brcc 3
	call @fail
	halt
	nop
	xor r3, r7, r0
	brcc 1
	brncc 3
	call @fail
	halt
	nop
	cmp.eq r0, 0x8080
	brcc 3
	call @fail
	halt
	nop
	# InlineAsm End
	call	@pass
	mov	0, r0
	ret

# ---------------------------------------------
# Global Data
# ---------------------------------------------
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"\t...pass\n"

.L.str.1:
	.asciz	"\t...fail\n"

	.comm	loadStoreOffset_mem,8,2
	.comm	loadStoreIndex_mem,16,2
	.comm	dmem0,2,2
	.comm	dmem2,2,2
	.comm	dmem4,2,2
	.comm	dmem6,2,2
.L.str.2:
	.asciz	"preMovCmp\n"

.L.str.3:
	.asciz	"preTestCall\n"

.L.str.4:
	.asciz	"preShortBranch\n"

.L.str.5:
	.asciz	"branchAddress\n"

.L.str.6:
	.asciz	"callAddress\n"

.L.str.7:
	.asciz	"branchCondtion\n"

.L.str.8:
	.asciz	"branchCondtion32\n"

.L.str.9:
	.asciz	"prefixEdge\n"

.L.str.10:
	.asciz	"byteShiftsAndExtensions\n"

.L.str.11:
	.asciz	"bitShifts\n"

.L.str.12:
	.asciz	"stackFrame\n"

.L.str.13:
	.asciz	"loadStoreOffset\n"

.L.str.14:
	.asciz	"loadStoreIndex\n"

.L.str.15:
	.asciz	"loadStoreAddress\n"

.L.str.16:
	.asciz	"selectAndSet\n"

.L.str.17:
	.asciz	"addSubNegTest\n"

.L.str.18:
	.asciz	"addSubTest32\n"

.L.str.19:
	.asciz	"andOrXorNotTest\n"


