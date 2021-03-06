//
// MUSOCKS5Request.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUSOCKS5Constants.h"

@protocol MUByteSource;
@protocol MUWriteBuffer;

@interface MUSOCKS5Request : NSObject
{
  NSString *hostname;
  int port;
  MUSOCKS5Reply reply;
}

@property (copy) NSString *hostname;
@property (assign, nonatomic) int port;

+ (id) socksRequestWithHostname: (NSString *) hostnameValue port: (int) portValue;

- (id) initWithHostname: (NSString *) hostnameValue port: (int) portValue;

- (void) appendToBuffer: (NSObject <MUWriteBuffer> *) buffer;
- (void) parseReplyFromByteSource: (NSObject <MUByteSource> *) source;
- (MUSOCKS5Reply) reply;

@end
