//
// MUServices.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUProfileRegistry.h"
#import "MUWorldRegistry.h"

@interface MUServices : NSObject

+ (MUProfileRegistry *) profileRegistry;
+ (MUWorldRegistry *) worldRegistry;

@end
