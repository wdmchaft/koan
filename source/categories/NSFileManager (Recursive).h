//
// NSFileManager (Recursive).h
//
// Copyright (C) 2004 3James Software
//
// This file is in the public domain.
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (Recursive)

- (BOOL) createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes recursive:(BOOL)recursive;
- (BOOL) createDirectoryRecursivelyAtPath:(NSString *)path attributes:(NSDictionary *)attributes;

@end
