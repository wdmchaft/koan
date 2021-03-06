//
// MUTelnetStateMachine.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

#import "MUTelnetProtocolHandler.h"
#import "MUTelnetState.h"

@class MUTelnetState;

@interface MUTelnetStateMachine : NSObject
{
  MUTelnetState *state;
  BOOL telnetConfirmed;
}

@property (retain, nonatomic) MUTelnetState *state;
@property (assign, nonatomic) BOOL telnetConfirmed;

+ (id) stateMachine;

- (void) confirmTelnet;
- (void) parse: (uint8_t) byte forProtocolHandler: (NSObject <MUTelnetProtocolHandler> *) protocolHandler;

@end
