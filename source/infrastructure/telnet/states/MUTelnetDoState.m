//
// MUTelnetDoState.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUTelnetDoState.h"

#import "MUTelnetTextState.h"

@implementation MUTelnetDoState

- (MUTelnetState *) parse: (uint8_t) byte
          forStateMachine: (MUTelnetStateMachine *) stateMachine
          protocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler
{
  [protocolHandler log: @"Received: IAC DO %@.", [protocolHandler optionNameForByte: byte]];
  [protocolHandler receivedDo: byte];
  return [MUTelnetTextState state];
}

@end
