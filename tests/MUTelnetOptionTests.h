//
// MUTelnetOptionTests.h
//
// Copyright (c) 2011 3James Software.
//

#import <J3Testing/J3TestCase.h>
#import "MUTelnetOption.h"
#import "MUTelnetProtocolHandler.h"

@interface MUTelnetOptionTests : J3TestCase <MUTelnetOptionDelegate>
{
  MUTelnetOption *option;
  char flags;
}

@end
