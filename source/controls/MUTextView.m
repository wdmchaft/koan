//
// MUTextView.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUTextView.h"

@implementation MUTextView

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
  SEL menuItemAction = [menuItem action];
  
  if (menuItemAction == @selector (paste:)
      || menuItemAction == @selector (pasteAsPlainText:)
      || menuItemAction == @selector (pasteAsRichText:))
  {
    if ([[self delegate] respondsToSelector: @selector (textView:pasteAsPlainText:)])
      return YES;
  }
  
  return [super validateMenuItem: menuItem];
}

- (void) insertText: (id) string
{
  BOOL result = NO;
  
  if ([[self delegate] respondsToSelector: @selector (textView:insertText:)])
    result = [(NSObject <MUTextViewDelegate> *) [self delegate] textView: self insertText: string];
  
  if (!result)
    [super insertText: string];
}

- (IBAction) paste: (id) sender
{
  [self pasteAsPlainText: sender];
}

- (IBAction) pasteAsPlainText: (id) sender
{
  BOOL result = NO;
  
  if ([[self delegate] respondsToSelector: @selector (textView:pasteAsPlainText:)])
    result = [(NSObject <MUTextViewDelegate> *) [self delegate] textView: self pasteAsPlainText: sender];
  
  if (!result)
    [super pasteAsPlainText: sender];
}

- (IBAction) pasteAsRichText: (id) sender
{
  [self pasteAsPlainText: sender];
}

@end
