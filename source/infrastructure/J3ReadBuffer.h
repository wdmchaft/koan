//
// J3ReadBuffer.h
//
// Copyright (c) 2005, 2006, 2007 3James Software
//

#import <Cocoa/Cocoa.h>

@protocol J3ReadBuffer

- (void) appendByte: (uint8_t) byte;
- (void) appendBytes: (const uint8_t *) bytes length: (unsigned) length;
- (const uint8_t *) bytes;
- (void) clear;
- (NSData *) dataByConsumingBytesToIndex: (unsigned) index;
- (NSData *) dataValue;
- (void) interpretBufferAsString;
- (BOOL) isEmpty;
- (unsigned) length;

@end

#pragma mark -

@interface J3ReadBuffer : NSObject <J3ReadBuffer>
{
  NSMutableData *dataBuffer;
  
  NSObject *delegate;
}

+ (id) buffer;

- (NSObject *) delegate;
- (void) setDelegate: (NSObject *) newDelegate;

@end

#pragma mark -

@interface NSObject (J3ReadBufferDelegate)

// The notification associated with this delegate method contains a userInfo
// dictionary with one field:
//
// Key: @"string"
// Value: the string provided by the read buffer

- (void) readBufferDidProvideString: (NSNotification *) notification;

@end
