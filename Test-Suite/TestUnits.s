	.text
	.file	"TestUnits.c"
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
	mov	1, r0
	ret

# ---------------------------------------------
# main
# ---------------------------------------------
	.globl	main
main:
	mov	&.L.str.2, r0
	call	@printstr
	# InlineAsm Start
		#pre add cmp
	mov 1, r0
	cmp.eq r0, 1
	brcc 3
	call @fail
	halt
	nop	#Error: branch should be taken
	# InlineAsm End
	call	@pass
	mov	&.L.str.3, r0
	call	@printstr
	# InlineAsm Start
		#pre call test
	mov 0, r0
	call @function
	cmp.eq r0, 1
	brcc 3
	call @fail
	halt
	nop
	# InlineAsm End
	call	@pass
	mov	&.L.str.4, r0
	call	@printstr
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
	call	@printstr
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
	call	@printstr
	# InlineAsm Start
	
	mov 1, r1
	mov 1, r2
	cmp.eq r1, r2
	brncc .Lcp0_eqerr
	brcc .Lcp0_eqend
.Lcp0_eqerr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp0_eqend:
	cmp.ne r1, r2
	brcc .Lcp0_neerr
	brncc .Lcp0_neend
.Lcp0_neerr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp0_neend:
	cmp.uge r1, r2
	brncc .Lcp0_ugeerr
	brcc .Lcp0_ugeend
.Lcp0_ugeerr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp0_ugeend:
	cmp.ult r1, r2
	brcc .Lcp0_ulterr
	brncc .Lcp0_ultend
.Lcp0_ulterr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp0_ultend:
	cmp.ge r1, r2
	brncc .Lcp0_geerr
	brcc .Lcp0_geend
.Lcp0_geerr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp0_geend:
	cmp.lt r1, r2
	brcc .Lcp0_lterr
	brncc .Lcp0_ltend
.Lcp0_lterr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp0_ltend:
	cmp.ugt r1, r2
	brcc .Lcp0_ugterr
	brncc .Lcp0_ugtend
.Lcp0_ugterr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp0_ugtend:
	cmp.gt r1, r2
	brcc .Lcp0_gterr
	brncc .Lcp0_gtend
.Lcp0_gterr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp0_gtend:
	mov 1, r4
	mov -1, r5
	cmp.eq r4, r5
	brcc .Lcp1_eqerr
	brncc .Lcp1_eqend
.Lcp1_eqerr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp1_eqend:
	cmp.ne r4, r5
	brncc .Lcp1_neerr
	brcc .Lcp1_neend
.Lcp1_neerr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp1_neend:
	cmp.uge r4, r5
	brcc .Lcp1_ugeerr
	brncc .Lcp1_ugeend
.Lcp1_ugeerr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp1_ugeend:
	cmp.ult r4, r5
	brncc .Lcp1_ulterr
	brcc .Lcp1_ultend
.Lcp1_ulterr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp1_ultend:
	cmp.ge r4, r5
	brncc .Lcp1_geerr
	brcc .Lcp1_geend
.Lcp1_geerr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp1_geend:
	cmp.lt r4, r5
	brcc .Lcp1_lterr
	brncc .Lcp1_ltend
.Lcp1_lterr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp1_ltend:
	cmp.ugt r4, r5
	brcc .Lcp1_ugterr
	brncc .Lcp1_ugtend
.Lcp1_ugterr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp1_ugtend:
	cmp.gt r4, r5
	brncc .Lcp1_gterr
	brcc .Lcp1_gtend
.Lcp1_gterr:
	call @fail
	halt
	nop	#Error: branch should be taken
.Lcp1_gtend:
	# InlineAsm End
	call	@pass
	mov	&.L.str.7, r0
	call	@printstr
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
	mov	&.L.str.8, r0
	call	@printstr
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
	# InlineAsm End
	call	@pass
	mov	&.L.str.9, r0
	call	@printstr
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
	mov	&.L.str.10, r0
	call	@printstr
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
	st.w r7, [r3, 64]
	ld.w [r3, 64], r2
	cmp.eq r2, r7
	brcc 3
	call @fail
	halt
	nop
	st.w r6, [r3, 66]
	ld.w [r3, 66], r2
	cmp.eq r2, r6
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
	nop	#consistency check
	cmp.eq r3, &loadStoreOffset_mem
	brcc 3
	call @fail
	halt
	nop	#r3 should still be the same
	# InlineAsm End
	call	@pass
	mov	&.L.str.11, r0
	call	@printstr
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
	mov	&.L.str.12, r0
	call	@printstr
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
	.asciz	"branchCondtion\n"

.L.str.7:
	.asciz	"prefixEdge\n"

.L.str.8:
	.asciz	"byteShiftsAndExtensions\n"

.L.str.9:
	.asciz	"stackFrame\n"

.L.str.10:
	.asciz	"loadStoreOffset\n"

.L.str.11:
	.asciz	"loadStoreIndex\n"

.L.str.12:
	.asciz	"loadStoreAddress\n"


