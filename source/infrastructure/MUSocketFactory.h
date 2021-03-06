//
// MUSocketFactory.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUMUDConnection.h"

@class MUProxySettings;

@interface MUSocketFactory : NSObject
{
  BOOL useProxy;
  MUProxySettings *proxySettings;
}

@property (assign, nonatomic) BOOL useProxy;
@property (retain) MUProxySettings *proxySettings;

+ (MUSocketFactory *) defaultFactory;

- (MUSocket *) makeSocketWithHostname: (NSString *) hostname port: (int) port;
- (void) saveProxySettings;
- (void) toggleUseProxy;
- (BOOL) useProxy;

@end
