//
// MUProfilesToolbarController.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

@interface MUProfilesToolbarController : NSObject <NSToolbarDelegate>
{
  NSToolbar *toolbar;
  
  IBOutlet NSWindow *window;
  IBOutlet NSWindowController *windowController;
}

@end
