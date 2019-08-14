//
//  testfile.c
//  RelayNou
//
//  Created by Joan on 13/08/19.
//  Copyright © 2019 Joan. All rights reserved.
//
 
// Operators that will call builtin functions
 
int asr16 ( int a, int b ) { return a >> b; }
unsigned lsr16 ( unsigned a, int b ) { return a >> b; }
int lsl16 ( int a, int b ) { return a << b; }

int multiply16s ( int a, int b ) { return a * b; }
unsigned multiply16u ( unsigned a, unsigned b ) { return a * b; }

long multiply32s ( long a, long b ) { return a * b; }
unsigned long multiply32u ( unsigned long a, unsigned long b ) { return a * b; }
 
int divide16s ( int a, int b ) { return a / b; }
int modulus16s ( int a, int b ) { return a % b; }
unsigned divide16u ( unsigned a, unsigned b ) { return a / b; }
unsigned modulus16u ( unsigned a, unsigned b ) { return a % b; }

long divide32s ( long a, long b ) { return a / b; }
long modulus32s ( long a, long b ) { return a % b; }
unsigned long divide32u ( unsigned long a, unsigned long b ) { return a / b; }
unsigned long modulus32u ( unsigned long a, unsigned long b ) { return a % b; }

// Operators that will be compiled inline

long asr32_1(long a) { return a >> 1; }
long unsigned lsr32_1(unsigned long a) { return a >> 1; }
long unsigned lsl32_1(unsigned long a) { return a << 1; }

long add32(long a, long b) { return a + b; }
long sub32(long a, long b) { return a - b; }

long btand32(long a, long b) { return a & b; }
long btor32(long a, long b) { return a | b; }
long btxor32(long a, long b) { return a ^ b; }

int eq32(long a, long b) { return a == b; }
int lt32(long a, long b) { return a < b; }
int gt32(long a, long b) { return a > b; }
int le32(long a, long b) { return a <= b; }
int ge32(long a, long b) { return a >= b; }

