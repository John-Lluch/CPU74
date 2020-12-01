//
//  systemio.c
//  RelayNou
//
//  Created by Joan on 23/10/19.
//  Copyright © 2019 Joan. All rights reserved.
//

#include "systemio.h"

void printstr( char *str )
{
  while ( *str )
    putchar( *str++ ); 
}   
        
  
void printnum( unsigned int num )
{
  int factors[] = {10000, 1000, 100, 10, 1};
  for ( int i=0 ; i<(sizeof factors)/2 ; ++i )
  {
    char ch = '0';
    while ( num >= factors[i])
    {
      ch = ch + 1;
      num = num - factors[i];
    }
    putchar( ch );
  }
}


