//
// J3PortFormatter.m
//
// Copyright (c) 2004, 2005 3James Software
//
// This file is in the public domain.
//

#import "J3PortFormatter.h"

@implementation J3PortFormatter

- (NSString *) stringForObjectValue:(id)object
{
  NSNumber *number = (NSNumber *) object;
  int value = [number intValue];
  
  if (value == 0 || number == nil)
    return nil;
  
  else return [number description];
}

- (BOOL) getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error
{
  int intResult;
  NSScanner *scanner;
  
  if ([string compare:@""] == NSOrderedSame ||
      string == nil)
  {
    if (object)
      *object = [NSNumber numberWithInt:0];
    return YES;
  }
  
  scanner = [NSScanner scannerWithString:string];
  
  if ([scanner scanInt:&intResult] && ([scanner isAtEnd]) && intResult > 0 && intResult < 65536)
  {
    if (object)
      *object = [NSNumber numberWithInt:intResult];
    return YES;
  }
  
  //if (error)
  //  *error = NSLocalizedString (GBLErrorConverting, nil);
  
  return NO;
}

@end
