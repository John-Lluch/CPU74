//
//  system.c
//  RelayNou
//
//  Created by Joan on 24/07/19.
//  Copyright © 2019 Joan. All rights reserved.
//

#include "system.h" 
 
// memcpy
__attribute__((builtin))
void *memcpy (void *dst, const void *src, unsigned int len)
{
  if ( !((int)src & 1) && !((int)dst & 1) )
  {   
    int *d = dst;
    const int *s = src;
    for ( int i=0 ; i<(len&0xfffe) ; i+=2 )
      *d++ = *s++;
    
    if ( len & 1 )
      *(char*)d = *(char*)s;

    return dst;
  }  

  char *d = dst; 
  const char *s = src; 
  for ( int i=0 ; i<len ; ++i )
    *d++ = *s++;

  return dst;
}

// Types and unions for 16 and 32 bit arithmetic
typedef          int  sint32_type   __attribute__ ((mode (SI)));
typedef unsigned int  uint32_type   __attribute__ ((mode (SI)));
typedef          int  sint16_type   __attribute__ ((mode (HI)));
typedef unsigned int  uint16_type   __attribute__ ((mode (HI)));

typedef union
{
  sint32_type all;
  struct
  {
    uint16_type lo;
    sint16_type hi;
  };
} S;

typedef union
{
  uint32_type all;
  struct
  {
    uint16_type lo;
    uint16_type hi;
  };
} U;

// 16 bit arithmetic shift right
__attribute__((builtin))
int __ashrhi3 (sint16_type a, int ammount)
{
  if ( ammount == 15 )
    return a >> 15;

  if (ammount >= 8)
    a >>= 8;

  for (int i = 0 ; i < (ammount & 0x7) ; ++i)
    a >>= 1;

  return a;
}

// 16 bit logical shift right
__attribute__((builtin))
unsigned int __lshrhi3 (uint16_type a, int ammount)
{
  if ( ammount == 15 )
    return a >> 15;

  if (ammount >= 8)
    a >>= 8;

  for (int i = 0 ; i < (ammount & 0x7) ; ++i)
    a >>= 1;

  return a;
}

// 16 bit shift left
__attribute__((builtin))
int __ashlhi3 (sint16_type a, int ammount)
{
  if (ammount >= 8)
    a <<= 8;

  for (int i = 0 ; i < (ammount & 0x7) ; ++i)
    a <<= 1;

  return a;
}

// 32 bit arithmetic shift right
__attribute__((builtin))
sint32_type __ashrsi3(sint32_type a, int ammount)
{
    const int bits_in_word = 8*sizeof(sint16_type);
    S sa;
    S sr;
    sa.all = a;

    if (ammount & bits_in_word) /* bits_in_word <= ammount < bits_in_dword */
    {
      /* sr.hi = sa.hi < 0 ? -1 : 0 */
      sr.hi = sa.hi >> (bits_in_word - 1);
      sr.lo = sa.hi >> (ammount - bits_in_word);
    }

    else  /* 0 <= ammount < bits_in_word */
    {
      if (ammount == 0)
          return a;

      sr.hi  = sa.hi >> ammount;
      sr.lo = (sa.hi << (bits_in_word - ammount)) | (sa.lo >> ammount);
    }

    return sr.all;
}

// 32 bit logical shift right
__attribute__((builtin))
uint32_type __lshrsi3(uint32_type a, unsigned int ammount)
{
    const int bits_in_word = 8*sizeof(sint16_type);
    U ua;
    U ur;
    ua.all = a;
    if (ammount & bits_in_word)  /* bits_in_word <= ammount < bits_in_dword */
    {
        ur.hi = 0;
        ur.lo = ua.hi >> (ammount - bits_in_word);
    }
    else  /* 0 <= ammount < bits_in_word */
    {
        if (ammount == 0)
            return a;
        ur.hi  = ua.hi >> ammount;
        ur.lo = (ua.hi << (bits_in_word - ammount)) | (ua.lo >> ammount);
    }
    return ur.all;
}

// 32 bit shift left
__attribute__((builtin))
sint32_type __ashlsi3(sint32_type a, int ammount)
{
    const int bits_in_word = 8*sizeof(sint16_type);
    S sa;
    S sr;
    sa.all = a;
 
    if (ammount & bits_in_word)  /* bits_in_word <= ammount < bits_in_dword */
    {
        sr.lo = 0;
        sr.hi = sa.lo << (ammount - bits_in_word);
    }

    else  /* 0 <= ammount < bits_in_word */
    {
        if (ammount == 0)
            return a;

        sr.lo  = sa.lo << ammount;
        sr.hi = (sa.hi << ammount) | (sa.lo >> (bits_in_word - ammount));
    }
    return sr.all;
}

// 16 bit multiplication
__attribute__((builtin))
uint16_type __mulhi3 (uint16_type a, uint16_type b)
{
  uint16_type r = 0;

  if (a > b)
  {
    uint16_type tmp = b;
    b = a;
    a = tmp;
  }

  while (a)
  {
    if (a & 1)
      r += b;
    a >>= 1;
    b <<= 1;
  }
  return r;
}

// 16 bit unsigned divide
__attribute__((builtin))
uint16_type __udivhi3 (uint16_type num, uint16_type den)
{
  uint16_type bit = 1;
  uint16_type res = 0;

  while (den < num && bit && !(den & (1U<<15)))
  {
    den <<=1;
    bit <<=1;
  }
  while (bit)
  {
    if (num >= den)
    {
      num -= den;
      res |= bit;
    }
    bit >>=1;
    den >>=1;
  }
  return res;
}

// 16 bit unsigned modulus
__attribute__((builtin))
uint16_type __umodhi3 (uint16_type num, uint16_type den)
{
  uint16_type bit = 1;

  while (den < num && bit && !(den & (1U<<15)))
  {
    den <<=1;
    bit <<=1;
  }
  while (bit)
  {
    if (num >= den)
    {
      num -= den;
    }
    bit >>=1;
    den >>=1;
  }
  return num;
}

// 16 bit signed divide
__attribute__((builtin))
sint16_type __divhi3 (sint16_type a, sint16_type b)
{
  int neg = 0;
  sint16_type res;

  if (a < 0)
  {
    a = -a;
    neg = !neg;
  }

  if (b < 0)
  {
    b = -b;
    neg = !neg;
  }

  res = (uint16_type)a / (uint16_type)b;  // will call __udivhi3

  if (neg)
    res = -res;

  return res;
}

// 16 bit signed modulus
__attribute__((builtin))
sint16_type __modhi3 (sint16_type a, sint16_type b)
{
  int neg = 0;
  sint16_type res;

  if (a < 0)
  {
    a = -a;
    neg = 1;
  }

  if (b < 0)
    b = -b;

  res = (uint16_type)a % (uint16_type)b;  // will call __umodhi3

  if (neg)
    res = -res;
 
  return res; 
}

// 32 bit multiplication
__attribute__((builtin))
uint32_type __mulsi3 (uint32_type a, uint32_type b)
{
  U ua;
  uint32_type r;

  if (a > b)
  {
    uint32_type tmp = b;
    b = a;
    a = tmp;
  }

  ua.all = a;
  r = 0;

  while ( ua.hi )
  {
    if ( ua.hi & 1 )
      r += b;
    ua.hi >>= 1;
    b <<= 1;
  }

  while ( ua.lo )
  {
    if ( ua.lo & 1 )
      r += b;
    ua.lo >>= 1;
    b <<= 1;
  }

  return r;
}

// 32 bit unsigned division
__attribute__((builtin))
uint32_type __udivsi3 (uint32_type num, uint32_type den)
{
  uint32_type bit = 1;
  uint32_type res = 0;

  while (den < num && bit && !(den & (1L<<31)))
  { 
    den <<=1;
    bit <<=1;
  } 

  while (bit)
  {
    if (num >= den)
    {
      num -= den;
      res |= bit;
    }
    bit >>= 1;
    den >>= 1;
  }
  return res;
}

// 32 bit modulus
__attribute__((builtin))
uint32_type __umodsi3 (uint32_type num, uint32_type den)
{
  uint32_type bit = 1;

  while (den < num && bit && !(den & (1L<<31)))
  {
    den <<=1;
    bit <<=1;
  }

  while (bit)
  {
    if (num >= den)
    {
      num -= den;
    }
    bit >>= 1;
    den >>= 1;
  }
  return num;
}

// 32 bit signed division
__attribute__((builtin))
sint32_type __divsi3 (sint32_type a, sint32_type b)
{
  int neg = 0;
  sint32_type res;

  if (a < 0)
  {
    a = -a;
    neg = !neg;
  }

  if (b < 0)
  {
    b = -b;
    neg = !neg;
  }

  res = (uint32_type)a / (uint32_type)b;  // will call __udivsi3

  if (neg)
    res = -res;

  return res;
}

// 32 bit signed modulus
__attribute__((builtin))
sint32_type __modsi3 (sint32_type a, sint32_type b)
{
  int neg = 0;
  long res;

  if (a < 0)
  {
    a = -a;
    neg = 1;
  }

  if (b < 0)
    b = -b;

  res = (uint32_type)a % (uint32_type)b;  //will call __umodsi3

  if (neg)
    res = -res;

  return res;
}

