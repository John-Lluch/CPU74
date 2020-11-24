//
//  TestUnits.c
//  RelayNou
//
//  Created by Joan on 15/11/20.
//  Copyright © 2020 Joan. All rights reserved.
//

#include "systemio.h"

//
// CPU74 isa functional tests
//
// Designed to test the CPU74 isa opcodes on an simulator or
// emulator with access to instruction memory addresses.
// Must be compiled with the LLVM based CPU74 compiler.
// The code will stop with a 'halt' instruction in case of
// failure. Check the immediatelly preceding code for the
// instructions to be checked.
//
// Set 'log' to 1 for text logging using the 'printstr' function
// NOTE that the log feature may use instructions
// that may not be tested and thus produce unpredictable results,
// unless at least the basic set of tests is passed
#define log 1

// Special 'halt' instruction test behaves opposite than the
// other tests. This should nornally be disabled
#define testHalt 0

// Convenience macros to emit assembly instructions
#define asm_begin asm( 
#define as "\n\t"
#define l "\n"
#define c "\t#"
#define asm_end );

//#define xstr(s) str(s)
//#define str(s) #s


// Convenience optional log macros

#if log
  #define beginTest(str) printstr(str);
  #define endTest pass();
#else
  #define beginTest(str)
  #define endTest
#endif

// Pass and Fail log functions

#if log
__attribute__((noinline))
void pass() {
  printstr( "\t...pass\n" );
}
__attribute__((noinline))
void fail() {
  printstr( "\t...fail\n" );
}
#endif

// Convenience macro to check a register value

#if log
  #define _halt \
  as "call @fail" \
  as "halt" \
  as "nop"
#else
  #define _halt \
  as "halt"
#endif

#if log
  #define _check(reg, value) \
  as "cmp.eq " #reg ", " #value \
  as "brcc 3" \
  _halt
#else
  #define _check(reg, value) \
  as "cmp.eq " #reg ", " #value \
  as "brcc 1" \
  _halt
#endif

//
// Tests begin here
//

// Test halt instruction
inline static void halt()
{
  asm_begin
  _halt
  asm_end
}

// Simple move and compare test
inline static void preMovCmp()
{
  beginTest("preMovCmp\n")
  asm_begin  c"pre add cmp"
  as "mov 1, r0"
  _check( r0, 1 )  c"Error: branch should be taken"
  asm_end
  endTest
}

// Call test helper
__attribute__((noinline))
int function() { return 1; }

// Simple call test
inline static void preTestCall()
{
  beginTest("preTestCall\n")
  asm_begin  c"pre call test"
  as "mov 0, r0"
  as "call @function"
  _check( r0, 1 )
  asm_end
  endTest
}

// Initial short branch test
inline static void preShortBranch()
{
  beginTest( "preShortBranch\n" )
  asm_begin  c"short branch test"
  as "mov 0, r2"
  as "add r2, 5, r2"    c"set NE flag"
  as "jmp .Lpsb_test"
l ".Lpsb_bwok:"
  as "mov 5, r3"
  as "add r2, r3, r3"
  as "brncc .Lpsb_forw"
  _halt                 c"branch should be taken"
  as "sub r3, 1, r3"    c"forward landing zone"
  as "sub r3, 1, r3"
  as "sub r3, 1, r3"
  as "sub r3, 1, r3"
  as "sub r3, 1, r3"
l ".Lpsb_forw:"
  as "sub r3, 1, r3"
  as "sub r3, 1, r3"
  as "sub r3, 1, r3"
  as "sub r3, 1, r3"
  as "sub r3, 1, r3"
  as "brcc .Lpsb_fwok"
  _halt                 c"branch should be taken"
  as "sub r2, 1, r2"    c"backward landing zone"
  as "sub r2, 1, r2"
  as "sub r2, 1, r2"
  as "sub r2, 1, r2"
  as "sub r2, 1, r2"
l ".Lpsb_back:"
  as "sub r2, 1, r2"
  as "sub r2, 1, r2"
  as "sub r2, 1, r2"
  as "sub r2, 1, r2"
  as "sub r2, 1, r2"
  as "brcc .Lpsb_bwok"
  _halt               c"branch should be taken"
l ".Lpsb_test:"
  as "brncc .Lpsb_back"
  _halt               c"Error: branch should be taken"
l ".Lpsb_fwok:"       c"success"
  asm_end
  endTest
}

// Branch to direct address
inline static void branchAddress()
{
  beginTest( "branchAddress\n" );
  asm_begin  c"branch address test"
  as "mov 5, r0"
  as "mov @.Lba0, r2"
l ".Lba_loop:"
  as "mov -1, r1"
  as "add r2, r0, r3"
  as "jmp r3"
l ".Lba0:"
  as "addx r1, 1, r1"  c".Lba0+0"
  as "addx r1, 1, r1"  c".Lba0+1"
  as "addx r1, 1, r1"  c".Lba0+2"
  as "addx r1, 1, r1"  c".Lba0+3"
  as "addx r1, 1, r1"  c".Lba0+4"
  as "addx r1, 1, r1"  c".Lba0+5"  c"branch address should land here"
  as "add r0, r1, r1"
  as "sub r1, 5, r1"
  as "brcc .LbaNext"
  _halt     c"Error: branch should be taken"
l ".LbaNext:"
  as "sub r0, 1, r0"
  as "brncc .Lba_loop"
l ".Lba_end:"
  asm_end
  endTest
}

// Branch condition
inline static void branchCondtion()
{
  beginTest( "branchCondtion\n" )
  
  asm_begin
  as "mov 1, r1"
  as "mov 1, r2"
  
  as "cmp.eq r1, r2"
  as "brncc .Lcp0_eqerr"
  as "brcc .Lcp0_eqend"
l ".Lcp0_eqerr:"
  _halt   c"Error: branch should be taken"
l ".Lcp0_eqend:"

  as "cmp.ne r1, r2"
  as "brcc .Lcp0_neerr"
  as "brncc .Lcp0_neend"
l ".Lcp0_neerr:"
  _halt   c"Error: branch should be taken"
l ".Lcp0_neend:"

  as "cmp.uge r1, r2"
  as "brncc .Lcp0_ugeerr"
  as "brcc .Lcp0_ugeend"
l ".Lcp0_ugeerr:"
  _halt   c"Error: branch should be taken"
l ".Lcp0_ugeend:"

  as "cmp.ult r1, r2"
  as "brcc .Lcp0_ulterr"
  as "brncc .Lcp0_ultend"
l ".Lcp0_ulterr:"
  _halt   c"Error: branch should be taken"
l ".Lcp0_ultend:"
  
  as "cmp.ge r1, r2"
  as "brncc .Lcp0_geerr"
  as "brcc .Lcp0_geend"
l ".Lcp0_geerr:"
  _halt   c"Error: branch should be taken"
l ".Lcp0_geend:"

  as "cmp.lt r1, r2"
  as "brcc .Lcp0_lterr"
  as "brncc .Lcp0_ltend"
l ".Lcp0_lterr:"
  _halt   c"Error: branch should be taken"
l ".Lcp0_ltend:"
  
  as "cmp.ugt r1, r2"
  as "brcc .Lcp0_ugterr"
  as "brncc .Lcp0_ugtend"
l ".Lcp0_ugterr:"
  _halt   c"Error: branch should be taken"
l ".Lcp0_ugtend:"

  as "cmp.gt r1, r2"
  as "brcc .Lcp0_gterr"
  as "brncc .Lcp0_gtend"
l ".Lcp0_gterr:"
  _halt   c"Error: branch should be taken"
l ".Lcp0_gtend:"
  
  as "mov 1, r4"
  as "mov -1, r5"
  
  as "cmp.eq r4, r5"
  as "brcc .Lcp1_eqerr"
  as "brncc .Lcp1_eqend"
l ".Lcp1_eqerr:"
  _halt   c"Error: branch should be taken"
l ".Lcp1_eqend:"

  as "cmp.ne r4, r5"
  as "brncc .Lcp1_neerr"
  as "brcc .Lcp1_neend"
l ".Lcp1_neerr:"
  _halt   c"Error: branch should be taken"
l ".Lcp1_neend:"

  as "cmp.uge r4, r5"
  as "brcc .Lcp1_ugeerr"
  as "brncc .Lcp1_ugeend"
l ".Lcp1_ugeerr:"
  _halt   c"Error: branch should be taken"
l ".Lcp1_ugeend:"

  as "cmp.ult r4, r5"
  as "brncc .Lcp1_ulterr"
  as "brcc .Lcp1_ultend"
l ".Lcp1_ulterr:"
  _halt   c"Error: branch should be taken"
l ".Lcp1_ultend:"
  
  as "cmp.ge r4, r5"
  as "brncc .Lcp1_geerr"
  as "brcc .Lcp1_geend"
l ".Lcp1_geerr:"
  _halt   c"Error: branch should be taken"
l ".Lcp1_geend:"

  as "cmp.lt r4, r5"
  as "brcc .Lcp1_lterr"
  as "brncc .Lcp1_ltend"
l ".Lcp1_lterr:"
  _halt  c"Error: branch should be taken"
l ".Lcp1_ltend:"
  
  as "cmp.ugt r4, r5"
  as "brcc .Lcp1_ugterr"
  as "brncc .Lcp1_ugtend"
l ".Lcp1_ugterr:"
  _halt  c"Error: branch should be taken"
l ".Lcp1_ugtend:"

  as "cmp.gt r4, r5"
  as "brncc .Lcp1_gterr"
  as "brcc .Lcp1_gtend"
l ".Lcp1_gterr:"
  _halt  c"Error: branch should be taken"
l ".Lcp1_gtend:"
  asm_end
  
  endTest
}

// Test prefixed moves and comparisons
inline static void prefixEdge()
{
  beginTest( "prefixEdge\n" )
  
  asm_begin
  as "mov 127, r3"       c"this should be extended to 0x007F"
  _check( r3, 127 )      c"this should be prefixed to 0x007F"
  as "mov -128, r2"      c"this should be extended to 0xFF80"
  _check( r2, -128 )     c"this should be prefixed to 0xFF80"
  as "mov 128, r1"       c"this should be prefixed to 0x0080"
  _check( r1, 128 )      c"this should be prefixed to 0x0080"
  as "mov 15, r6"        c"this should be extended to 0x000F"
 _check( r6, 15 )        c"this should be extended to 0x000F"
  as "mov -16, r5"       c"this should be extended to 0xFFF0"
  _check( r5, -16 )      c"this should be extended to 0xFFF0"
  as "mov 16, r4"        c"this should be extended to 0x000F"
  _check( r4, 16 )       c"this should be prefixed to 0x000F"
   asm_end
  
  endTest
}


inline static void byteShiftsAndExtensions()
{
  beginTest( "byteShiftsAndExtensions\n" )
  asm_begin
  as "mov 0xAA55, r0"
  as "mov 0x55AA, r7"
  
  as "asrb r0, r1"
  _check( r1, 0xFFAA )
  as "asrb r7, r1"
  _check( r1, 0x0055 )
  as "lsrb r0, r1"
  _check( r1, 0x00AA )
  as "lsrb r7, r1"
  _check( r1, 0x0055 )
  as "lslb r0, r1"
  _check( r1, 0x5500 )
  as "lslb r7, r1"
  _check( r1, 0xAA00 )
  as "sext r0, r1"
  _check( r1, 0x0055 )
  as "sext r7, r1"
  _check( r1, 0xFFAA )
  as "zext r0, r1"
  _check( r1, 0x0055 )
  as "zext r7, r1"
  _check( r1, 0x00AA )
  asm_end
  
  endTest
}

//;shifts
//rASL                                ;expected result ASL & ROL -carry
//rROL    db  0,2,$86,$04,$82,0
//rROLc   db  1,3,$87,$05,$83,1       ;expected result ROL +carry
//rLSR                                ;expected result LSR & ROR -carry
//rROR    db  $40,0,$61,$41,$20,0
//rRORc   db  $c0,$80,$e1,$c1,$a0,$80 ;expected result ROR +carry
//fASL                                ;expected flags for shifts
//fROL    db  fzc,0,fnc,fc,fn,fz      ;no carry in
//fROLc   db  fc,0,fnc,fc,fn,0        ;carry in
//fLSR
//fROR    db  0,fzc,fc,0,fc,fz        ;no carry in
//fRORc   db  fn,fnc,fnc,fn,fnc,fn    ;carry in

inline static void bitShifts()
{
  beginTest( "bitShifts\n" );
  endTest
}
  

inline static void stackFrame()
{
  beginTest( "stackFrame\n" );
  
  asm_begin
  as "mov 0x55AA, r4"
  as "mov 0x8134, r5"
  as "mov 0xFF00, r6"
  as "mov 0xABCD, r7"
  
  c"save stack pointer"
  as "addx SP, 0, r0"     c"save stack pointer"
  as "addx SP, -8, SP"
  
  c"word store"
  as "st.w  r4, [SP, 6]"  c"push words"
  as "st.w  r5, [SP, 4]"
  as "st.w  r6, [SP, 2]"
  as "st.w  r7, [SP, 0]"
  
  c"load word test, retrieve in reverse register order"
  as "ld.w [SP, 6], r7"
  _check( r7, 0x55AA )
  as "ld.w [SP, 4], r6"
  _check( r6, 0x8134 )
  as "ld.w [SP, 2], r5"
  _check( r5, 0xFF00 )
  as "ld.w [SP, 0], r4"
  _check( r4, 0xABCD )
  
  c"efective address test"
  as "addx SP, 6, r1"
  as "ld.w [r1, 0], r1"
  _check( r1, r7 )
  as "addx SP, 6, r1"
  as "ld.w [r1, -6], r1"
  _check( r1, r4 )

  c"load byte test"
  as "ld.sb [SP, 6], r1"
  _check( r1, 0xFFAA )   c"sign extended 0xAA"
  as "ld.sb [SP, 7], r1"
  _check( r1, 0x0055 )   c"sign extended 0x55"
  as "ld.sb [SP, 5], r1"
  _check( r1, 0xFF81 )   c"sign extended 0x81"
  as "ld.sb [SP, 4], r1"
  _check( r1, 0x0034 )   c"sign extended 0x34"
  as "ld.sb [SP, 2], r1"
  _check( r1, 0x0000 )   c"sign extended 0x00"
  as "ld.sb [SP, 3], r1"
  _check( r1, 0xFFFF)    c"sign extended 0xFF"
 
  c"byte store"
  as "mov 0x22, r1"
  as "st.b  r1, [SP, 7]"    c"push bytes"
  as "mov 0xDD, r1"
  as "st.b  r1, [SP, 4]"
  as "mov 0x77, r1"
  as "st.b  r1, [SP, 3]"
  as "mov 0x99, r1"
  as "st.b  r1, [SP, 0]"
  
  c"load test"
  as "ld.w [SP, 0], r1"
  _check( r1, 0xAB99)
  as "ld.w [SP, 2], r1"
  _check( r1, 0x7700 )
  as "ld.w [SP, 4], r1"
  _check( r1, 0x81DD )
  as "ld.w [SP, 6], r1"
  _check( r1, 0x22AA )

  c"long stack frame test"
  as "addx SP, -258, SP"
  as "ld.w [SP, 264], r2"
  _check( r2, 0x22AA )
  as "ld.sb [SP, 264], r2" 
  _check( r2, 0xFFAA )
  as "ld.sb [SP, 265], r2"
  as "addx SP, 258, SP"   c"this should not modify flags"
  _check( r2, 0x0022 )

  c"efective frame address test"
  as "addx SP, 44, r1"
  as "sub r1, 44, r1"
  as "mov r1, SP"
  as "addx SP, 8, SP"
  as "addx SP, 0, r1"
  _check( r0, r1 )     c"check stack pointer"
  asm_end

  endTest
}

//inline static void branchRelative()
//{
//  asm_begin
//  as "mov 255, r3"  c"max forward range"
//l".Lrange_loop"
//
//l ".Lrange_fw"
//
//l ".Lrange_op"
//
//l ".Lrange_adr"
//
//l ".Lrange_ok"
//
//  as "brcc .Lrange_end"
//  as "jmp .Lrange_loop"
//l ".Lrange_end"
//  asm_end
//}


unsigned int loadStoreOffset_mem[4];
inline static void loadStoreOffset()
{
  beginTest( "loadStoreOffset\n" );
  
  asm_begin
  as "mov &loadStoreOffset_mem, r3"
  as "mov 0x55AA, r4"
  as "mov 0x8134, r5"
  as "mov 0xFF00, r6"
  as "mov 0xABCD, r7"
  
  c"word store"
  as "st.w  r4, [r3, 6]"  c"store words"
  as "st.w  r5, [r3, 4]"
  as "st.w  r6, [r3, 2]"
  as "st.w  r7, [r3, 0]"
  
  c"load word test, retrieve in reverse register order"
  as "ld.w [r3, 6], r7"
  _check( r7, 0x55AA )
  as "ld.w [r3, 4], r6"
  _check( r6, 0x8134 )
  as "ld.w [r3, 2], r5"
  _check( r5, 0xFF00 )
  as "ld.w [r3, 0], r4"
  _check( r4, 0xABCD )

  c"load byte test"
  as "ld.sb [r3, 6], r1"
  _check( r1, 0xFFAA )   c"sign extended 0xAA"
  as "ld.sb [r3, 7], r1"
  _check( r1, 0x0055 )   c"sign extended 0x55"
  as "ld.sb [r3, 5], r1"
  _check( r1, 0xFF81 )   c"sign extended 0x81"
  as "ld.sb [r3, 4], r1"
  _check( r1, 0x0034 )   c"sign extended 0x34"
  as "ld.sb [r3, 2], r1"
  _check( r1, 0x0000 )   c"sign extended 0x00"
  as "ld.sb [r3, 3], r1"
  _check( r1, 0xFFFF )   c"sign extended 0xFF"

  c"byte store"
  as "mov 0x22, r1"
  as "st.b  r1, [r3, 7]"    c"store bytes"
  as "mov 0xDD, r1"
  as "st.b  r1, [r3, 4]"
  as "mov 0x77, r1"
  as "st.b  r1, [r3, 3]"
  as "mov 0x99, r1"
  as "st.b  r1, [r3, 0]"
  
  c"mixed load test"
  as "ld.w [r3, 0], r1"
  _check( r1, 0xAB99 )
  as "ld.w [r3, 2], r1"
  _check( r1, 0x7700 )
  as "ld.w [r3, 4], r1"
  _check( r1, 0x81DD )
  as "ld.w [r3, 6], r1"
  _check( r1, 0x22AA )

  c"long word load/store test"
  as "st.w r7, [r3, 64]"
  as "ld.w [r3, 64], r2"
  _check( r2, r7 )
  as "st.w r6, [r3, 66]"
  as "ld.w [r3, 66], r2"
  _check( r2, r6 )

  c"long mixed byte load/store test"
  as "st.b r7, [r3, 32]"  c"this should be 0xAA"
  as "ld.sb [r3, 32], r2"
  as "sext r7, r1"
  _check( r1, r2 )
  as "st.b r6, [r3, 33]"  c"this should be 0x34"
  as "ld.sb [r3, 33], r2"
  as "sext r6, r1"
  _check( r1, r2 )
  as "ld.w [r3, 32], r1" 
  _check( r1, 0x34AA )
  
  c"consistency check"
  _check( r3, &loadStoreOffset_mem )    c"r3 should still be the same"
  asm_end
  
  endTest
}

//typedef union
//{
//  unsigned int w;
//  struct { unsigned char lo, hi; };
//} MemWord;


int loadStoreIndex_mem[8];
inline static void loadStoreIndex()
{
// Code is equivalent to the following C code with minor changes
/*...........................................
  volatile static int a[16]; // set volatile to honour all load/stores

  // store word
  for ( int i=0 ; i<8 ; i++ )
    a[i] = i+0x55FA;

  // test word
  for ( int i=0 ; i<8 ; i++ )
    if (a[i] != i+0x55FA)
      asm( "halt" );  // failed word load test

  // store byte
  for ( int i=0 ; i<16 ; i++ )
    ((char*)a)[i] = i+0x7C;

  // load signed byte test
  // initial value is chosen so that a sign change happens along the loop
  for ( int i=0 ; i<16 ; i++ )
    if ( ((char*)a)[i] != (char)(i+0x7C) )
      asm( "halt" );    // failed byte load test

  // load unsigned byte test
  for ( int i=0 ; i<16 ; i++ )
    if ( ((unsigned char*)a)[i] != (unsigned char)(i+0x7C) )
      asm( "halt" );    // failed byte load test

  // mixed test
  for ( int i=0 ; i<16 ; i+=2)
  {
    MemWord v; v.w = a[i/2];
    if ( v.lo != i+0x7C ) asm( "halt" );
    if ( v.hi != i+1+0x7C ) asm ( "halt" );
  }
........................................*/


  beginTest( "loadStoreIndex\n" );
  asm_begin
  c"store word"
  as "mov  0, r1"
  as "mov  &loadStoreIndex_mem, r0"
l ".Llsi_1:"
  as "mov  r1, r2"
  as "add  r2, 0x55FA, r2"
  as "st.w  r2, [r0, r1]"
  as "addx  r1, 1, r1"
  as "cmp.eq  r1, 8"
  as "brncc  .Llsi_1"
  
  c"load word"
  as "mov  0, r1"
l ".Llsi_3:"
  as "ld.w  [r0, r1], r2"
  as "mov  r1, r3"
  as "add  r3, 0x55FA, r3"
  _check( r3, r2 )
  as "addx  r1, 1, r1"
  as "cmp.eq  r1, 8"
  as "brncc  .Llsi_3"
  
  c"store byte"
  as "mov  0, r1"
l ".Llsi_7:"
  as "mov  r1, r2"
  as "add  r2, 0x7C, r2"
  as "st.b  r2, [r1, r0]"
  as "addx  r1, 1, r1"
  as "cmp.eq  r1, 16"
  as "brncc  .Llsi_7"
  
  c"laod signed byte"
  c"initial value is chosen so that a sign change happens along the loop"
  as "mov  0, r1"
l ".Llsi_9:"
  as "ld.sb  [r1, r0], r2"
  as "mov  r1, r3"
  as "add  r3, 0x7C, r3"
  as "sext  r3, r3"
  _check( r2, r3 )
  as "addx  r1, 1, r1"
  as "cmp.eq  r1, 16"
  as "brncc  .Llsi_9"

  c "load unsigned byte"
 as " mov  0, r1"
l ".Llsi_13:"
  as "ld.zb  [r1, r0], r2"
  as "mov  r1, r3"
  as "add  r3, 0x7C, r3"
  as "zext  r3, r3"
  _check( r2, r3 )
  as "addx  r1, 1, r1"
  as "cmp.eq  r1, 16L"
  as "brncc  .Llsi_13"
  
   c "load mixed"
  as "mov  0, r1"
  as "lsr  r0, r0"
l ".Llsi_17:"
  as "ld.w  [r1, r0], r2"
  as "mov  r1, r3"
  as "add  r3, 0x7C, r3"
  as "zext  r2, r4"
  as "lsrb  r2, r2"
  _check( r3, r4 )
  as "mov  r1, r3"
  as "add  r3, 0x7D, r3"
  _check( r3, r2 )
  as "addx  r1, 2, r1"
  as "cmp.ugt  r1, 15"
  as "brncc  .Llsi_17"
  asm_end

  endTest
}

//
int *dmem0, *dmem2, *dmem4, *dmem6;
inline static void loadStoreAddress()
{
  beginTest( "loadStoreAddress\n" );

  asm_begin
  as "mov 0x55AA, r4"
  as "mov 0x8134, r5"
  as "mov 0xFF00, r6"
  as "mov 0xABCD, r7"
  
  c"word store"
  as "st.w  r4, [&dmem6]"  c"store words"
  as "st.w  r5, [&dmem4]"
  as "st.w  r6, [&dmem2]"
  as "st.w  r7, [&dmem0]"
  
  c"load word test, retrieve in reverse register order"
  as "ld.w [&dmem6], r7"
  _check( r7, 0x55AA )
  as "ld.w [&dmem4], r6"
  _check( r6, 0x8134 )
  as "ld.w [&dmem2], r5"
  _check( r5, 0xFF00 )
  as "ld.w [&dmem0], r4"
  _check( r4, 0xABCD )

  c"load byte test"
  as "ld.sb [&dmem6], r1"
  _check( r1, 0xFFAA )   c"sign extended 0xAA"
  as "ld.sb [&dmem6+1], r1"
  _check( r1, 0x0055 )   c"sign extended 0x55"
  as "ld.sb [&dmem4+1], r1"
  _check( r1, 0xFF81 )   c"sign extended 0x81"
  as "ld.sb [&dmem4], r1"
  _check( r1, 0x0034 )   c"sign extended 0x34"
  as "ld.sb [&dmem2], r1"
  _check( r1, 0x0000 )   c"sign extended 0x00"
  as "ld.sb [&dmem2+1], r1"
  _check( r1, 0xFFFF )   c"sign extended 0xFF"

  c"byte store"
  as "mov 0x22, r1"
  as "st.b  r1, [&dmem6+1]"    c"store bytes"
  as "mov 0xDD, r1"
  as "st.b  r1, [&dmem4]"
  as "mov 0x77, r1"
  as "st.b  r1, [&dmem2+1]"
  as "mov 0x99, r1"
  as "st.b  r1, [&dmem0]"
  
  c"mixed load test"
  as "ld.w [&dmem0], r1"
  _check( r1, 0xAB99 )
  as "ld.w [&dmem2], r1"
  _check( r1, 0x7700 )
  as "ld.w [&dmem4], r1"
  _check( r1, 0x81DD )
  as "ld.w [&dmem6], r1"
  _check( r1, 0x22AA )

  c"long word load/store test"
  as "st.w r7, [&dmem0+512]"
  as "ld.w [&dmem0+512], r2"
  _check( r2, r7 )

  c"long byte load/store test"
  as "st.b r7, [&dmem0+256]"  c"this should be 0xAA"
  as "ld.sb [&dmem0+256], r2"
  as "sext r7, r1"
  _check( r1, r2 )
  as "st.b r6, [&dmem0+257]"  c"this should be 0x34"
  as "ld.sb [&dmem0+257], r2"
  as "sext r6, r1"
  _check( r1, r2 )
  
  as "ld.w [&dmem0+256], r1"
  _check( r1, 0x34AA )
  
l ".Llsa_end:"
  asm_end

  endTest
}

//
//
//

int main()
{
#if testHalt
  halt();
#endif

  preMovCmp();
  preTestCall();
  preShortBranch();
  branchAddress();
  branchCondtion();
  prefixEdge();
  byteShiftsAndExtensions();
  stackFrame();
  loadStoreOffset();
  loadStoreIndex();
  loadStoreAddress();
}


