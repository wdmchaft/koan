//
// MUByteSet.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUByteSet.h"

@implementation MUByteSet

+ (id) byteSet
{
  return [[[self alloc] init] autorelease];
}

+ (id) byteSetWithBytes: (int) first, ...
{
  va_list args;
  va_start (args, first);
  id result = [[[self alloc] initWithFirstByte: first remainingBytes: args] autorelease];
  va_end (args);
  return result;
}

+ (id) byteSetWithBytes: (const uint8_t *) bytes length: (size_t) length
{
  return [[[self alloc] initWithBytes: bytes length: length] autorelease];
}

- (void) addByte: (uint8_t) byte;
{
  if (!contains[byte])
    contains[byte] = YES;
}

- (void) addBytes: (uint8_t) first, ...
{
  va_list args;
  va_start (args, first);
  [self addFirstByte: first remainingBytes: args];
  va_end (args);
}

- (void) addFirstByte: (int) first remainingBytes: (va_list) bytes
{
  int current;

  [self addByte: first];
  while ((current = va_arg (bytes, int)) != -1)
    contains[current] = YES;  
}

- (BOOL) containsByte: (uint8_t) byte
{
  return contains[byte];
}

- (NSData *) dataValue
{
  NSMutableData *result = [NSMutableData data];
  uint8_t byte[1];
  for (unsigned i = 0; i <= UINT8_MAX; i++)
  {
    if (contains[i])
    {
      byte[0] = i;
      [result appendBytes: byte length: 1];
    }
  }
  return result;
}

- (id) init
{
  if (!(self = [super init]))
    return nil;
  
  for (unsigned i = 0; i <= UINT8_MAX; i++)
    contains[i] = NO;
  
  return self;
}

- (id) initWithBytes: (const uint8_t *) bytes length: (size_t) length
{
  if (![self init])
    return nil;
  
  for (unsigned i = 0; i < length; i++)
    [self addByte: bytes[i]];
  
  return self;
}

- (id) initWithFirstByte: (int) first remainingBytes: (va_list) bytes
{
  if (![self init])
    return nil;

  [self addFirstByte: first remainingBytes: bytes];
  
  return self;
}

- (MUByteSet *) inverseSet
{
  MUByteSet *set = [MUByteSet byteSet];
  
  for (unsigned i = 0; i <= UINT8_MAX; i++)
    set->contains[i] = !contains[i];
  
  return set;
}

- (void) removeByte: (uint8_t) byte
{
  contains[byte] = NO;
}

@end
