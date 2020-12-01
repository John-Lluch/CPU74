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
// that may not be tested and thus produce unpredictable result
// unless at least the basic set of tests is passed

#define log 1

// The 'halt' instruction test behaves opposite than the
// other tests. This should nornally be enabled on the
// first run to veryfy that halt behaves as expected,
// then disabled for all the other tests
//
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
  #define beginTest(str) test(str);
  #define endTest pass();
#else
  #define beginTest(str)
  #define endTest
#endif

// Pass and Fail log functions

#if log
__attribute__((noinline))
void test( char *str) {
  printstr( str );
}
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
#define _checkcc \
  as "brncc 1" \
  as "brcc 3" \
  _halt
#define _checkncc \
  as "brcc 1" \
  as "brncc 3" \
  _halt

#else
#define _check(reg, value) \
  as "cmp.eq " #reg ", " #value \
  as "brcc 1" \
  _halt
#define _checkcc \
  as "brncc 1" \
  as "brcc 1" \
  _halt
#define _checkncc \
  as "brcc 1" \
  as "brncc 1" \
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
  _check( r0, 1 )  c"function should be called"
  asm_end
  endTest
}

// Call test helper
__attribute__((noinline))
void function()
{
  asm_begin
  as "mov r1, r0"
  _check( r1, r0 )  c"function should be called"
  asm_end
}

// Simple call test
inline static void preTestCall()
{
  beginTest("preTestCall\n")
  asm_begin  c"pre call test"
  as "mov 3, r1"
  as "call @function"
  _check( r0, 3 )
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

// Call to direct address
inline static void callAddress()
{
  beginTest( "callAddress\n" );
  asm_begin
  as "mov 3, r1"
  as "mov @function, r0"
  as "call r0"
  _check( r0, 3 )
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
  _checkcc
  as "cmp.ne r1, r2"
  _checkncc
  as "cmp.uge r1, r2"
  _checkcc
  as "cmp.ult r1, r2"
  _checkncc
  as "cmp.ge r1, r2"
  _checkcc
  as "cmp.lt r1, r2"
  _checkncc
  as "cmp.ugt r1, r2"
  _checkncc
  as "cmp.gt r1, r2"
  _checkncc
  as "sub r1, r2, r3"
  _checkcc
  as "add r1, r2, r3"
  _checkncc
  
  as "cmp.eq r1, 1"
  _checkcc
  as "cmp.ne r1, 1"
  _checkncc
  as "cmp.uge r1, 1"
  _checkcc
  as "cmp.ult r1, 1"
  _checkncc
  as "cmp.ge r1, 1"
  _checkcc
  as "cmp.lt r1, 1"
  _checkncc
  as "cmp.ugt r1, 1"
  _checkncc
  as "cmp.gt r1, 1"
  _checkncc
  as "sub r1, 1, r1"
  _checkcc
  as "add r2, 1, r2"
  _checkncc
  
  as "mov 1, r4"
  as "mov -1, r5"
  as "cmp.eq r4, r5"
  _checkncc
  as "cmp.ne r4, r5"
  _checkcc
  as "cmp.uge r4, r5"
  _checkncc
  as "cmp.ult r4, r5"
  _checkcc
  as "cmp.ge r4, r5"
  _checkcc
  as "cmp.lt r4, r5"
  _checkncc
  as "cmp.ugt r4, r5"
  _checkncc
  as "cmp.gt r4, r5"
  _checkcc
  as "sub r4, r5, r3"
  _checkncc
  as "add r4, r5, r3"
  _checkcc
  
  as "cmp.eq r4, -1"
  _checkncc
  as "cmp.ne r4, -1"
  _checkcc
  as "cmp.uge r4, -1"
  _checkncc
  as "cmp.ult r4, -1"
  _checkcc
  as "cmp.ge r4, -1"
  _checkcc
  as "cmp.lt r4, -1"
  _checkncc
  as "cmp.ugt r4, -1"
  _checkncc
  as "cmp.gt r4, -1"
  _checkcc
  
  as "add r5, 1, r5"   c"should be 0"
  _checkcc
  as "sub r5, 1, r5"  c"should be -1"
  _checkncc
  as "sub r5, -1, r5"   c"should be 0"
  _checkcc
  as "add r5, -1, r5"   c"should be -1"
  _checkncc
  _check( r5, -1 )
  asm_end
  endTest
}

// Branch condition 32 bits
inline static void branchCondtion32()
{
  beginTest( "branchCondtion32\n" )
  asm_begin
  as "mov 1, r1"
  as "mov 1, r2"
  as "mov 1, r3"
  as "mov 1, r4"
  
  as "cmp.eq r1, r3"   c"low word"
  as "cmpc.eq r2, r4"  c"high word"
  _checkcc
  as "cmp.ne r1, r3"
  as "cmpc.ne r2, r4"
  _checkncc
  as "cmp.uge r1, r3"
  as "cmpc.uge r2, r4"
  _checkcc
  as "cmp.ult r1, r3"
  as "cmpc.ult r2, r4"
  _checkncc
  as "cmp.ge r1, r3"
  as "cmpc.ge r2, r4"
  _checkcc
  as "cmp.lt r1, r3"
  as "cmpc.lt r2, r4"
  _checkncc
  as "cmp.ugt r1, r3"
  as "cmpc.ugt r2, r4"
  _checkncc
  as "cmp.gt r1, r3"
  as "cmpc.gt r2, r4"
  _checkncc
  as "sub r1, r3, r5"
  as "subc r2, r4, r6"
  _checkcc
  as "add r1, r3, r5"
  as "addc r2, r4, r6"
  _checkncc
  
  as "mov 1, r1"
  as "mov 1, r2"
  as "mov 0, r3"
  as "mov 1, r4"
  
  as "cmp.eq r1, r3"   c"low word"
  as "cmpc.eq r2, r4"  c"high word"
  _checkncc
  as "cmp.ne r1, r3"
  as "cmpc.ne r2, r4"
  _checkcc
  as "cmp.uge r1, r3"
  as "cmpc.uge r2, r4"
  _checkcc
  as "cmp.ult r1, r3"
  as "cmpc.ult r2, r4"
  _checkncc
  as "cmp.ge r1, r3"
  as "cmpc.ge r2, r4"
  _checkcc
  as "cmp.lt r1, r3"
  as "cmpc.lt r2, r4"
  _checkncc
  as "cmp.ugt r1, r3"
  as "cmpc.ugt r2, r4"
  _checkcc
  as "cmp.gt r1, r3"
  as "cmpc.gt r2, r4"
  _checkcc
  as "sub r1, r3, r5"
  as "subc r2, r4, r6"
  _checkncc
  as "add r1, r3, r5"
  as "addc r2, r4, r6"
  _checkncc
  
  as "mov 1, r1"
  as "mov 1, r2"
  as "mov 0, r3"
  as "mov -1, r4"
  
  as "cmp.eq r1, r3"   c"low word"
  as "cmpc.eq r2, r4"  c"high word"
  _checkncc
  as "cmp.ne r1, r3"
  as "cmpc.ne r2, r4"
  _checkcc
  as "cmp.uge r1, r3"
  as "cmpc.uge r2, r4"
  _checkncc
  as "cmp.ult r1, r3"
  as "cmpc.ult r2, r4"
  _checkcc
  as "cmp.ge r1, r3"
  as "cmpc.ge r2, r4"
  _checkcc
  as "cmp.lt r1, r3"
  as "cmpc.lt r2, r4"
  _checkncc
  as "cmp.ugt r1, r3"
  as "cmpc.ugt r2, r4"
  _checkncc
  as "cmp.gt r1, r3"
  as "cmpc.gt r2, r4"
  _checkcc
  as "sub r1, r3, r5"
  as "subc r2, r4, r6"
  _checkncc
  as "add r1, r3, r5"
  as "addc r2, r4, r6"
  _checkncc
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

// Byte shifts and byte extensions
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
  as "sextw r0, r1"
  _check( r1, 0xffff)
  as "sextw r7, r1"
  _check( r1, 0 )
  asm_end
  
  endTest
}

// Bit shifts
inline static void bitShifts()
{
  beginTest( "bitShifts\n" );
  asm_begin
  as "mov 0x55AA, r0"
  as "mov 0xAA55, r2"
  
  c"shift left"
  as "add r0, r0, r1"
  _check( r1, 0xAB54 )
  as "add r2, r2, r3"    c"this produces 0x54AA + carry"
  _check( r3, 0x54AA )
  as "add r0, r0, r1"
  as "addc r2, r2, r3"    c"carry should not apply"
  _check( r3, 0x54AA )
  as "add r2, r2, r3"    c"this produces 0x54AA + carry"
  as "addc r3, r3, r3"   c"this consumes carry and produces 0xA955"
  _check( r3, 0xA955 )
  as "add r2, r2, r3"    c"this produces 0x54AA + carry"
  as "addc r2, r2, r3"   c"this consumes carry and procudes 0x54AB + carry"
  as "addc r3, r3, r3"
  _check( r3, 0xA957 )
  
  c"shift right"
  as "lsr r0, r1"
  _check( r1, 0x2AD5 )
  as "lsr r2, r3"    c"this produces 0x552A + carry"
  _check( r3, 0x552A )
  as "lsr r0, r1"
  as "lsrc r2, r3"    c"carry should not apply"
  _check( r3, 0x552A )
  as "lsr r2, r3"    c"this produces 0x552A + carry"
  as "lsrc r3, r3"   c"this consumes carry and produces 0xAA95"
  _check( r3, 0xAA95 )
  as "lsr r2, r3"    c"this produces 0x552A + carry"
  as "lsrc r2, r3"   c"this consumes carry and procudes 0xD52A + carry"
  as "lsrc r3, r3"
  _check( r3, 0xEA95 )
 
  c"arithmetic shift right"
  as "asr r0, r1"
  _check( r1, 0x2AD5 )
  as "asr r2, r3"       c"this produces carry"
  _check( r3, 0xD52A )
  as "asr r2, r3"       c"this produces carry, but should not affect asr"
  as "asr r0, r1"       c"this should still produce 0x2AD5"
  _check( r1, 0x2AD5 )
  as "asr r2, r3"       c"this produces carry"
  as "lsrc r3, r3"      c"this consumes carry and produces 0xAA95"
  _check( r3, 0xEA95 )
  as "asr r0, r1"       c"this does not produce carry"
  as "lsrc r2, r3"
 _check( r3, 0x552A )   c"carry should not apply"
 
  asm_end
  endTest
}
  
 // Stack frame
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

// Load/store offset
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
  as "st.w r7, [r3, 62]"
  as "ld.w [r3, 62], r2"
  _check( r2, r7 )
  as "st.w r6, [r3, 64]"
  as "ld.w [r3, 64], r2"
  _check( r2, r6 )
  
  c"long word load/store test (2)"
  as "st.w r4, [r3, 104]"
  as "ld.w [r3, 104], r2"
  _check( r2, r4 )
  as "addx r3, 104, r2"
  as "ld.w [r2, 0], r2"
  _check( r2, r4 )

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
  
  c"long mixed byte load/store test (2)"
  as "st.b r7, [r3, 104]"  c"this should be 0xAA"
  as "ld.sb [r3, 104], r2"
  as "sext r7, r1"
  _check( r1, r2 )
  as "st.b r6, [r3, 105]"  c"this should be 0x34"
  as "ld.sb [r3, 105], r2"
  as "sext r6, r1"
  _check( r1, r2 )
  as "ld.w [r3, 104], r1"
  _check( r1, 0x34AA )
  as "addx r3, 104, r2"
  as "ld.w [r2, 0], r1"
  _check( r1, 0x34AA )
  
  c"consistency check"
  _check( r3, &loadStoreOffset_mem )    c"r3 should still be the same"
  asm_end
  
  endTest
}

// Load/store index
int loadStoreIndex_mem[8];
inline static void loadStoreIndex()
{

/*
  // Test code is equivalent to the following C code with minor changes
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
*/

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

// Load/store address
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

// Select and set
inline static void selectAndSet()
{
  beginTest( "selectAndSet\n" )
  asm_begin
  as "mov 0, r0"
  as "mov 1, r1"
  as "mov 2, r2"
  as "mov 3, r3"
  as "cmp.gt r1, r0"
  as "selcc r2, r3, r4"
  as "selcc 0, r3, r5"
  as "selcc r2, 0, r6"
  as "setcc r7"
  _check( r4, 2 )
  _check( r5, 0 )
  _check( r6, 2 )
  _check( r7, 1 )
  as "cmp.gt r0, r1"
  as "selcc r2, r3, r4"
  as "selcc 0, r3, r5"
  as "selcc r2, 0, r6"
  as "setcc r7"
  _check( r4, 3 )
  _check( r5, 3 )
  _check( r6, 0 )
  _check( r7, 0 )
  asm_end
  endTest
}


// Arithmetic add, sub, neg
inline static void addSubNegTest()
{
  beginTest( "addSubNegTest\n" )

/*
  // Add testing code is roughtly equivalent to this
  int cnt = 0;
  for (int a=0 ; a<16 ; a++, cnt-=15 )
    for ( int b=0 ; b<16 ; b++, cnt++ )
      if ( a+b != cnt ) asm ("halt");
*/

  asm_begin
l".def cnt = r2"
l".def a = r0"
l".def b = r1"
  as "mov 0, cnt"
  as "mov 0, a"
l ".Lasa_outer:"
  as "mov 0, b"
l ".Lasa_inner:"
  as "add a, b, r3"
  _check( cnt, r3)
  as "addx b, 1, b"
  as "addx cnt, 1, cnt"
  as "cmp.lt b, 16"
  as "brcc .Lasa_inner"
  as "addx a, 1, a"
  as "sub cnt, 15, cnt"
  as "cmp.lt a, 16"
  as "brcc .Lasa_outer"
  
/*
  // Sub testing code is roughtly equivalent to this
  int cnt = 0;
  for (int a=15 ; a>=0 ; a--, cnt-=17 )
    for ( int b=15 ; b>=0 ; b--, cnt++ )
      if ( a-b != cnt ) asm ("halt");
*/

  as "mov 0, cnt"
  as "mov 15, a"
l ".Lass_outer:"
  as "mov 15, b"
l ".Lass_inner:"
  as "sub a, b, r3"
  _check( cnt, r3)
  as "sub b, 1, b"
  as "addx cnt, 1, cnt"
  as "cmp.ge b, 0"
  as "brcc .Lass_inner"
  as "sub a, 1, a"
  as "sub cnt, 17, cnt"
  as "cmp.ge a, 16"
  as "brcc .Lass_outer"
  
/*
  // Neg testing code is roughtly equivalent to this
  int cnt = -15;
  for ( int b=15 ; b>=0 ; b--, cnt++ )
      if ( -b != cnt ) asm ("halt");
*/
  
  as "mov -15, cnt"
  as "mov 15, b"
l ".Lasn_inner:"
  as "neg b, r3"
  _check( cnt, r3)
  as "sub b, 1, b"
  as "addx cnt, 1, cnt"
  as "cmp.ge b, 0"
  as "brcc .Lasn_inner"
  
  asm_end
  endTest
}


// Arithmetic add, sub, neg
inline static void addSubTest32()
{
  beginTest( "addSubTest32\n" )

/*
  // Add testing code is essentially equivalent to this
  long cnt = 65530
  for (long a=65530 ; a<65546 ; a++, cnt-=15 )
    for ( long b=0 ; b<16 ; b++, cnt++ )
      if ( a+b != cnt ) asm ("halt");
*/

  asm_begin
l".def cntlo = r4"
l".def cnthi = r5"
l".def al = r0"
l".def ah = r1"
l".def bl = r2"
l".def bh = r3"
  as "mov 0, r6"
  as "mov 0xFFFA, cntlo"
  as "mov 0x0000, cnthi"
  as "mov 0xFFFA, al"
  as "mov 0x0000, ah"
l ".Lasa32_outer:"
  as "mov 0, bl"
  as "mov 0, bh"
l ".Lasa32_inner:"
  as "add al, bl, r6"
  as "addc ah, bh, r7"
  as "cmp.eq cntlo, r6"
  as "cmpc.eq cnthi, r7"
  _checkcc
  as "add bl, 1, bl"
  as "mov 0, r6"
  as "addc bh, r6, bh"
  as "add cntlo, 1, cntlo"
  as "addc cnthi, r6, cnthi"
  as "cmp.lt bl, 16"
  as "cmpc.lt bh, 0"
  as "brcc .Lasa32_inner"
  as "add al, 1, al"
  as "addc ah, r6, ah"
  as "sub cntlo, 15, cntlo"
  as "subc cnthi, r6, cnthi"
  as "cmp.lt al, 0x000A"
  as "cmpc.lt ah, 0x0001"
  as "brcc .Lasa32_outer"
  
/*
  // Sub testing code is essentially equivalent to this
  long cnt = 65530;
  for (long a=65545 ; a>=65530 ; a--, cnt-=17 )
    for ( long b=15 ; b>=0 ; b--, cnt++ )
      if ( a-b != cnt ) asm ("halt");
*/

  as "mov 0, r6"
  as "mov 0xFFFA, cntlo"
  as "mov 0x0000, cnthi"
  as "mov 0x0009, al"
  as "mov 0x0001, ah"
l ".Lass32_outer:"
  as "mov 15, bl"
  as "mov 0, bh"
l ".Lass32_inner:"
  as "sub al, bl, r6"
  as "subc ah, bh, r7"
  as "cmp.eq cntlo, r6"
  as "cmpc.eq cnthi, r7"
  _checkcc
  as "sub bl, 1, bl"
  as "mov 0, r6"
  as "subc bh, r6, bh"
  as "add cntlo, 1, cntlo"
  as "addc cnthi, r6, cnthi"
  as "cmp.ge bl, 0"
  as "cmpc.ge bh, 0"
  as "brcc .Lass32_inner"
  as "sub al, 1, al"
  as "subc ah, r6, ah"
  as "sub cntlo, 17, cntlo"
  as "subc cnthi, r6, cnthi"
  as "cmp.ge al, 0xFFFA"
  as "cmpc.ge ah, 0x0000"
  as "brcc .Lass32_outer"
  
  asm_end
  endTest
}

// Logic and, or, xor, not
inline static void andOrXorNotTest()
{
  beginTest( "andOrXorNotTest\n" )
  asm_begin
  
  c"test patterns for AND"
  as "mov 0x0F0F, r0"
  as "mov 0xFFFF, r1"
  as "mov 0x7F7F, r2"
  as "mov 0x8080, r3"
  as "mov 0xF0F0, r4"
  as "mov 0xFFFF, r5"
  as "mov 0xFFFF, r6"
  as "mov 0xFFFF, r7"
  as "and r0, r4, r0"
  _checkcc
  _check( r0, 0x0000 )
  as "and r1, r5, r0"
  _checkncc
  _check( r0, 0xFFFF )
  as "and r2, r6, r0"
  _checkncc
  _check( r0, 0x7F7F )
  as "and r3, r7, r0"
  _checkncc
  _check( r0, 0x8080 )
  as "mov 0x0F0F, r0"
  as "and r0, 0xF0F0, r0"
  _checkcc
  _check( r0, 0x0000 )
  as "and r1, -1, r0"
  _checkncc
  _check( r0, 0xFFFF )
  as "and r2, -1, r0"
  _checkncc
  _check( r0, 0x7F7F )
  as "and r3, -1, r0"
  _checkncc
  _check( r0, 0x8080 )
  as "and r1, 0, r0"
  _checkcc
  _check( r0, 0 )
  
  c"test patterns for OR"
  as "mov 0x0000, r0"
  as "mov 0x1F1F, r1"
  as "mov 0x7171, r2"
  as "mov 0x8080, r3"
  as "mov 0x0000, r4"
  as "mov 0xF1F1, r5"
  as "mov 0x1F1F, r6"
  as "mov 0x0000, r7"
  as "or r0, r4, r0"
  _checkcc
  _check( r0, 0x0000 )
  as "or r1, r5, r0"
  _checkncc
  _check( r0, 0xFFFF )
  as "or r2, r6, r0"
  _checkncc
  _check( r0, 0x7F7F )
  as "or r3, r7, r0"
  _checkncc
  _check( r0, 0x8080 )
  
  c"test patterns for XOR"
  as "mov 0xFFFF, r0"
  as "mov 0x0F0F, r1"
  as "mov 0x8F8F, r2"
  as "mov 0x8F8F, r3"
  as "mov 0xFFFF, r4"
  as "mov 0xF0F0, r5"
  as "mov 0xF0F0, r6"
  as "mov 0x0F0F, r7"
  as "xor r0, r4, r0"
  _checkcc
  _check( r0, 0x0000 )
  as "xor r1, r5, r0"
  _checkncc
  _check( r0, 0xFFFF )
  as "xor r2, r6, r0"
  _checkncc
  _check( r0, 0x7F7F )
  as "xor r3, r7, r0"
  _checkncc
  _check( r0, 0x8080 )
  asm_end
  endTest
}
 

// Entry code

int main()
{ 
#if testHalt
  halt();
#endif

  preMovCmp();
  preTestCall();
  preShortBranch();
  branchAddress();
  callAddress();
  branchCondtion();
  branchCondtion32();
  prefixEdge();
  byteShiftsAndExtensions();
  bitShifts();
  stackFrame();
  loadStoreOffset();
  loadStoreIndex();
  loadStoreAddress();
  selectAndSet();
  addSubNegTest();
  addSubTest32();
  andOrXorNotTest();
}


