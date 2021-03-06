//
// MUHistoryRing.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUHistoryRing : NSObject
{
  NSString *buffer;
  NSMutableArray *ring;
  NSMutableDictionary *updates;
  NSInteger cursor;
  NSInteger searchCursor;
}

+ (id) historyRing;

- (NSUInteger) count;
- (NSString *) stringAtIndex: (NSInteger) ringIndex;

// These methods are all O(1).

- (void) saveString: (NSString *) string;
- (void) updateString: (NSString *) string;
- (NSString *) currentString;
- (NSString *) nextString;
- (NSString *) previousString;

- (void) resetSearchCursor;

// These methods are all O(n).

- (NSUInteger) numberOfUniqueMatchesForStringPrefix: (NSString *) prefix;
- (NSString *) searchForwardForStringPrefix: (NSString *) prefix;
- (NSString *) searchBackwardForStringPrefix: (NSString *) prefix;

@end
