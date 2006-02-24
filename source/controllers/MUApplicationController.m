//
// MUApplicationController.m
//
// Copyright (c) 2004, 2005 3James Software
//

#import "FontNameToDisplayNameTransformer.h"
#import "J3PortFormatter.h"
#import "MUApplicationController.h"
#import "MUConnectionWindowController.h"
#import "MUGrowlService.h"
#import "MUPlayer.h"
#import "MUPreferencesController.h"
#import "MUProfilesController.h"
#import "MUServices.h"
#import "J3ConnectionFactory.h"
#import "J3UpdateController.h"
#import "MUWorld.h"

@interface MUApplicationController (Private)

- (IBAction) changeFont:(id)sender;
- (void) colorPanelColorDidChange:(NSNotification *)notification;
- (IBAction) openConnection:(id)sender;
- (void) openConnectionWithController:(MUConnectionWindowController *)controller;
- (void) rebuildConnectionsMenuWithAutoconnect:(BOOL)autoconnect;
- (void) updateApplicationBadge;
- (void) worldsDidChange:(NSNotification *)notification;

@end

#pragma mark -

@implementation MUApplicationController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  NSMutableDictionary *initialValues = [NSMutableDictionary dictionary];
  NSValueTransformer *transformer = [[FontNameToDisplayNameTransformer alloc] init];
  NSData *archivedLightGray = [NSArchiver archivedDataWithRootObject:[NSColor lightGrayColor]];
  NSData *archivedBlack = [NSArchiver archivedDataWithRootObject:[NSColor blackColor]];
  NSData *archivedBlue = [NSArchiver archivedDataWithRootObject:[NSColor blueColor]];
  NSData *archivedPurple = [NSArchiver archivedDataWithRootObject:[NSColor purpleColor]];
  NSFont *fixedFont = [NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]];
  
  [NSValueTransformer setValueTransformer:transformer forName:@"FontNameToDisplayNameTransformer"];
  
  [defaults setObject:[NSArray array] forKey:MUPWorlds];
  [defaults setObject:[NSNumber numberWithInt:0] forKey:MUPCheckForUpdatesInterval];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
  
  [initialValues setObject:archivedBlack forKey:MUPBackgroundColor];
  [initialValues setObject:[fixedFont fontName] forKey:MUPFontName];
  [initialValues setObject:[NSNumber numberWithFloat:[fixedFont pointSize]] forKey:MUPFontSize];
  [initialValues setObject:archivedBlue forKey:MUPLinkColor];
  [initialValues setObject:archivedLightGray forKey:MUPTextColor];
  [initialValues setObject:archivedPurple forKey:MUPVisitedLinkColor];
  [initialValues setObject:[NSNumber numberWithBool:YES] forKey:MUPPlaySounds];
  [initialValues setObject:[NSNumber numberWithBool:YES] forKey:MUPSilentWhenActive];
  
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValues];
  
  [MUGrowlService growlService];
}

- (void) awakeFromNib
{
	J3PortFormatter *newConnectionPortFormatter = [[[J3PortFormatter alloc] init] autorelease];
	
  [MUServices profileRegistry];
  [MUServices worldRegistry];
  
  connectionWindowControllers = [[NSMutableArray alloc] init];
  
  [self rebuildConnectionsMenuWithAutoconnect:YES];
  
  [newConnectionPortField setFormatter:newConnectionPortFormatter];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(colorPanelColorDidChange:)
                                               name:NSColorPanelColorDidChangeNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(worldsDidChange:)
                                               name:MUWorldsDidChangeNotification
                                             object:nil];
  
  unreadCount = 0;
  [self updateApplicationBadge];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
  [connectionWindowControllers release];
  [profilesController release];
  [proxySettingsController release];
  [super dealloc];
}

- (BOOL) validateMenuItem:(id <NSMenuItem>)anItem
{
  if ([anItem isEqual:useProxyMenuItem])
    [useProxyMenuItem setState:[[J3ConnectionFactory currentFactory] useProxy]?NSOnState:NSOffState];
  return YES;
}

#pragma mark -
#pragma mark Actions

- (IBAction) chooseNewFont:(id)sender
{
  NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
  NSString *fontName = [values valueForKey:MUPFontName];
  int fontSize = [[values valueForKey:MUPFontSize] floatValue];
  NSFont *font = [NSFont fontWithName:fontName size:fontSize];
  
  if (font == nil)
    font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
  
  [[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
}

- (IBAction) connectToURL:(NSURL *)url
{
	MUConnectionWindowController *controller;
	MUWorld *world;
  
  if (![[url scheme] isEqualToString:@"telnet"])
    return;
  
  world = [[MUWorld alloc] initWithName:[url host]
                               hostname:[url host]
                                   port:[url port]
                                    URL:@""
                                players:nil];
  controller = [[MUConnectionWindowController alloc] initWithWorld:world];
	
	[self openConnectionWithController:controller];
	
	[world release];
  [controller release];
}

- (IBAction) connectUsingPanelInformation:(id)sender
{
	MUConnectionWindowController *controller;
	MUWorld *world = [[MUWorld alloc] initWithName:[newConnectionHostnameField stringValue]
																				hostname:[newConnectionHostnameField stringValue]
																						port:[NSNumber numberWithInt:[newConnectionPortField intValue]]
                                             URL:@""
                                         players:nil];
  controller = [[MUConnectionWindowController alloc] initWithWorld:world];
	
	if ([newConnectionSaveWorldButton state] == NSOnState)
		[[MUServices worldRegistry] insertObject:world inWorldsAtIndex:[[MUServices worldRegistry] count]];
	
	[self openConnectionWithController:controller];
	[newConnectionPanel close];
	
	[world release];
  [controller release];
}

- (IBAction) openBugsWebPage:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://bugs.3james.com/"]];
}

- (IBAction) openNewConnectionPanel:(id)sender
{
	[newConnectionHostnameField setObjectValue:nil];
	[newConnectionPortField setObjectValue:nil];
	[newConnectionSaveWorldButton setState:NSOffState];
	[newConnectionPanel makeFirstResponder:newConnectionHostnameField];
  [newConnectionPanel makeKeyAndOrderFront:self];
}

- (void) recursivelyConfirmClose:(BOOL)cont
{
  if (cont)
  {
    unsigned count = [connectionWindowControllers count];

    while (count--)
    {
      MUConnectionWindowController *controller = [connectionWindowControllers objectAtIndex:count];
      if (controller && [controller isConnected])
      {
        [controller confirmClose:@selector(recursivelyConfirmClose:)];
        return;
      }
    }
  }
  
  [NSApp replyToApplicationShouldTerminate:cont];
}

- (IBAction) showPreferencesPanel:(id)sender
{
  [preferencesController showPreferencesPanel:sender];
}

- (IBAction) showProfilesPanel:(id)sender
{
  if (!profilesController)
    profilesController = [[MUProfilesController alloc] init];
  if (profilesController)
    [profilesController showWindow:self];
}

- (IBAction) showProxySettings:(id)sender;
{
  if (!proxySettingsController)
    proxySettingsController = [[MUProxySettingsController alloc] init];
  if (proxySettingsController)
    [proxySettingsController showWindow:self];
}

- (IBAction) toggleUseProxy:(id)sender;
{
  [[J3ConnectionFactory currentFactory] toggleUseProxy];
}

#pragma mark -
#pragma mark NSApplication delegate

- (void) applicationDidBecomeActive:(NSNotification *)notification
{
  unreadCount = 0;
  [self updateApplicationBadge];
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id checkAutomatically = [defaults objectForKey:MUPCheckForUpdatesAutomatically];
  
  if (!checkAutomatically)
  {
    int choice;
    NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString (MULShouldCheckAutomaticallyForUpdatesTitle, nil), MUApplicationName]
                                     defaultButton:NSLocalizedString (MULYes, nil)
                                   alternateButton:NSLocalizedString (MULNo, nil)
                                       otherButton:nil
                         informativeTextWithFormat:[NSString stringWithFormat:NSLocalizedString (MULShouldCheckAutomaticallyForUpdatesMessage, nil), MUApplicationName]];
    
    choice = [alert runModal];
    
    if (choice == NSAlertDefaultReturn)
      [defaults setBool:YES forKey:MUPCheckForUpdatesAutomatically];
    else if (choice == NSAlertAlternateReturn)
      [defaults setBool:NO forKey:MUPCheckForUpdatesAutomatically];
  }
  
  if ([defaults boolForKey:MUPCheckForUpdatesAutomatically])
  {
    [updateController checkForUpdatesAutomatically];
  }
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)application
{
  unsigned count = [connectionWindowControllers count];
  unsigned openConnections = 0;
  int choice;
  
  while (count--)
  {
    MUConnectionWindowController *controller = [connectionWindowControllers objectAtIndex:count];
    if (controller && [controller isConnected])
      openConnections++;
  }
  
  if (openConnections > 0)
  {
    NSAlert *alert;
    int choice = NSAlertDefaultReturn;
    NSString *title = [NSString stringWithFormat:
      (openConnections == 1 ? NSLocalizedString (MULConfirmQuitTitleSingular, nil)
                            : NSLocalizedString (MULConfirmQuitTitlePlural, nil)),
      openConnections];
  
    if (openConnections > 1)
    {
      alert = [NSAlert alertWithMessageText:title
                              defaultButton:NSLocalizedString (MULConfirm, nil)
                            alternateButton:NSLocalizedString (MULCancel, nil)
                                otherButton:NSLocalizedString (MULQuitImmediately, nil)
                  informativeTextWithFormat:NSLocalizedString (MULConfirmQuitMessage, nil)];
    
      choice = [alert runModal];
      
      if (choice == NSAlertAlternateReturn)
        return NSTerminateCancel;
    }
    
    if (choice == NSAlertDefaultReturn)
    {
      [self recursivelyConfirmClose:YES];
      return NSTerminateLater;
    }
  }
  
  return NSTerminateNow;
}

- (void) applicationWillTerminate:(NSNotification *)notification
{
  unreadCount = 0;
  [self updateApplicationBadge];
  
  [[MUServices worldRegistry] saveWorlds];
  [[MUServices profileRegistry] saveProfiles];
  [[J3ConnectionFactory currentFactory] saveProxySettings];
}

#pragma mark -
#pragma mark MUConnectionWindowController delegate

- (void) connectionWindowControllerWillClose:(NSNotification *)notification
{
  MUConnectionWindowController *controller = [notification object];
  
  [controller retain];
  [connectionWindowControllers removeObject:controller];
  [controller autorelease];
}

- (void) connectionWindowControllerDidReceiveText:(NSNotification *)notification
{
  if (![NSApp isActive])
  {
    NSSound *blow = [NSSound soundNamed:@"Blow"];
    [NSApp requestUserAttention:NSInformationalRequest];
    
    [blow play];
    unreadCount++;
    [self updateApplicationBadge];
  }
}

@end

#pragma mark -

@implementation MUApplicationController (Private)

- (IBAction) changeFont:(id)sender
{
  [preferencesController changeFont];
}

- (void) colorPanelColorDidChange:(NSNotification *)notification
{
	[preferencesController colorPanelColorDidChange];
}

- (IBAction) openConnection:(id)sender
{
	MUConnectionWindowController *controller;
  MUProfile *profile = [sender representedObject];
  controller = [[MUConnectionWindowController alloc] initWithProfile:profile];
	
	[self openConnectionWithController:controller];
	
  [controller release];
}

- (void) openConnectionWithController:(MUConnectionWindowController *)controller
{
  [controller setDelegate:self];
  
  [connectionWindowControllers addObject:controller];
  [controller showWindow:self];
  [controller connect:nil];
}

- (void) rebuildConnectionsMenuWithAutoconnect:(BOOL)autoconnect
{
  MUWorldRegistry *registry = [MUServices worldRegistry];
  MUProfileRegistry *profiles = [MUServices profileRegistry];
  int i, worldsCount = [registry count], menuCount = [openConnectionMenu numberOfItems];
  
  for (i = menuCount - 1; i >= 0; i--)
  {
    [openConnectionMenu removeItemAtIndex:i];
  }
  
  for (i = 0; i < worldsCount; i++)
  {
    MUWorld *world = [registry worldAtIndex:i];
    MUProfile *profile = [profiles profileForWorld:world];
    NSArray *players = [world players];
    NSMenuItem *worldItem = [[NSMenuItem alloc] init];
    NSMenu *worldMenu = [[NSMenu alloc] initWithTitle:[world name]];
    NSMenuItem *connectItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString (MULConnectWithoutLogin, nil)
                                                         action:@selector(openConnection:)
                                                  keyEquivalent:@""];
    int j, playersCount = [players count];
    
    [connectItem setTarget:self];
    [connectItem setRepresentedObject:profile];

    if (autoconnect)
    {
      [profile setWorld:world];
      if ([profile autoconnect])
        [self openConnection:connectItem];
    }
    
    for (j = 0; j < playersCount; j++)
    {
      MUPlayer *player = [players objectAtIndex:j];
      profile = [profiles profileForWorld:world player:player];
    
      NSMenuItem *playerItem = [[NSMenuItem alloc] initWithTitle:[player name]
                                                          action:@selector(openConnection:)
                                                   keyEquivalent:@""];
      [playerItem setTarget:self];
      [playerItem setRepresentedObject:profile];
      
      if (autoconnect)
      {
        [profile setWorld:world];
        [profile setPlayer:player];
        if ([profile autoconnect])
          [self openConnection:playerItem];
      }
      
      [worldMenu addItem:playerItem];
      [playerItem release];
    }
    
    if (playersCount > 0)
    {
      [worldMenu addItem:[NSMenuItem separatorItem]];
    }
    
    [worldMenu addItem:connectItem];
    [worldItem setTitle:[world name]];
    [worldItem setSubmenu:worldMenu];
    [openConnectionMenu addItem:worldItem];
    [worldItem release];
    [worldMenu release];
    [connectItem release];
  }
}

- (void) updateApplicationBadge
{
  NSDictionary *attributeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSColor whiteColor], NSForegroundColorAttributeName,
    [NSFont fontWithName:@"Helvetica Bold" size:25.0], NSFontAttributeName,
    nil];
  NSAttributedString *unreadCountString =
    [NSAttributedString attributedStringWithString:[NSString stringWithFormat:@"%@", [NSNumber numberWithUnsignedInt:unreadCount]]
                                        attributes:attributeDictionary];
  NSImage *appImage, *newAppImage, *badgeImage;
  NSSize newAppImageSize, badgeImageSize;
  NSPoint unreadCountStringLocationPoint;
  
  appImage = [NSImage imageNamed:@"NSApplicationIcon"];
  
  newAppImage = [[NSImage alloc] initWithSize:[appImage size]];
  newAppImageSize = [newAppImage size];
  
  [newAppImage lockFocus];
  
  [appImage drawInRect:NSMakeRect (0, 0, newAppImageSize.width, newAppImageSize.height)
              fromRect:NSMakeRect (0, 0, [appImage size].width, [appImage size].height)
             operation:NSCompositeCopy
              fraction:1.0];
  
  if (unreadCount > 0)
  {
    if (unreadCount < 100)
      badgeImage = [NSImage imageNamed:@"badge-1-2"];
    else if (unreadCount < 1000)
      badgeImage = [NSImage imageNamed:@"badge-3"];
    else if (unreadCount < 10000)
      badgeImage = [NSImage imageNamed:@"badge-4"];
    else
      badgeImage = [NSImage imageNamed:@"badge-5"];
    
    
    badgeImageSize = [badgeImage size];
    
    [badgeImage drawInRect:NSMakeRect (newAppImageSize.width - badgeImageSize.width,
                                       newAppImageSize.height - badgeImageSize.height,
                                       badgeImageSize.width,
                                       badgeImageSize.height)
                  fromRect:NSMakeRect (0, 0, badgeImageSize.width, badgeImageSize.height)
                 operation:NSCompositeSourceOver
                  fraction:1.0];
    
    if (unreadCount < 10)
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 19.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    else if (unreadCount < 100)
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 12.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    else if (unreadCount < 1000)
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 14.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    else if (unreadCount < 10000)
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 12.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    else
    {
      unreadCountStringLocationPoint = NSMakePoint (newAppImageSize.width - badgeImageSize.width + 10.0,
                                                    newAppImageSize.height - badgeImageSize.height + 12.0);
    }
    
    
    [unreadCountString drawAtPoint:unreadCountStringLocationPoint];
  }
  
  [newAppImage unlockFocus];
  
  [NSApp setApplicationIconImage:newAppImage];
  [newAppImage release];
}

- (void) worldsDidChange:(NSNotification *)notification
{
  [self rebuildConnectionsMenuWithAutoconnect:NO];
}

@end
