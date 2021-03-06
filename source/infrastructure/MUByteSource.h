//
// MUByteSource.h
//
// Copyright (c) 2011 3James Software.
//

@protocol MUByteSource

- (NSUInteger) availableBytes;
- (BOOL) hasDataAvailable;
- (void) poll;
- (NSData *) readExactlyLength: (size_t) length;
- (NSData *) readUpToLength: (size_t) length;

@end
