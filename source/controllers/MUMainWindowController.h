//
// MUMainWindowController.h
//
// Copyright (C) 2004 Tyler Berry and Samuel Tesla
//
// Koan is free software; you can redistribute it and/or modify it under the
// terms of the GNU General Public License as published by the Free Software
// Foundation; either version 2 of the License, or (at your option) any later
// version.
//
// Koan is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// Koan; if not, write to the Free Software Foundation, Inc., 59 Temple Place,
// Suite 330, Boston, MA 02111-1307 USA
//

#import <Cocoa/Cocoa.h>
#import "Connections/MUTelnetConnection.h"

@interface MUMainWindowController : NSWindowController
{
  IBOutlet NSTextField *hostNameField;
  IBOutlet NSTextField *portField;
  IBOutlet NSTextView *textView;
  IBOutlet NSTextField *inputField;
  IBOutlet NSButton *connectButton;
  IBOutlet NSButton *disconnectButton;
  
  MUTelnetConnection *_telnetConnection;
  
  NSMutableArray *_historyArray;
  int _historyIndex;
}

- (IBAction) connect:(id)sender;
- (IBAction) disconnect:(id)sender;
- (IBAction) writeLine:(id)sender;

- (void) telnetDidReadLine:(MUTelnetConnection *)telnet;

- (void) displayString:(NSString *)string;
@end