//
// MUProfilesSection.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>
#import "MUSection.h"

@interface MUProfilesSection : MUSection

@property (assign) NSMutableArray *children;

- (id) initWithName: (NSString *) newName;

@end
