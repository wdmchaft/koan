//
// NSURL (Allocating).m
//
// Copyright (C) 2004 3James Software
//
// This file is in the public domain.
//

#import "NSURL (Allocating).h"

@implementation NSURL (Allocating)

+ (NSURL *) URLWithScheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path
{
  return [[[NSURL alloc] initWithScheme:scheme host:host path:path] autorelease];
}

@end
