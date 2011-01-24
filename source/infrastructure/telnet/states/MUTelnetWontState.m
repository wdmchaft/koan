//
// MUTelnetWontState.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUTelnetWontState.h"

#import "MUTelnetTextState.h"

@implementation MUTelnetWontState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC WONT %@.", [protocolHandler optionNameForByte: byte]];
  [protocolHandler receivedWont: byte];
  return [MUTelnetTextState state];
}

@end
