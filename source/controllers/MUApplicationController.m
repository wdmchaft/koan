//
// MUApplicationController.m
//
// Copyright (c) 2011 3James Software.
//

#import "FontNameToDisplayNameTransformer.h"
#import "MUPortFormatter.h"
#import "MUAcknowledgementsController.h"
#import "MUApplicationController.h"
#import "MUConnectionWindowController.h"
#import "MUGrowlService.h"
#import "MUPlayer.h"
#import "MUPreferencesController.h"
#import "MUProfilesController.h"
#import "MUProxySettingsController.h"
#import "MUServices.h"
#import "MUSocketFactory.h"
#import "MUWorld.h"

@interface MUApplicationController (Private)

- (IBAction) changeFont: (id) sender;
- (void) colorPanelColorDidChange: (NSNotification *) notification;
- (id) infoValueForKey: (NSString *) key;
- (IBAction) openConnection: (id) sender;
- (void) openConnectionWithController: (MUConnectionWindowController *) controller;
- (void) playNotificationSound;
- (void) rebuildConnectionsMenuWithAutoconnect: (BOOL) autoconnect;
- (void) recursivelyConfirmClose: (BOOL) cont;
- (BOOL) shouldPlayNotificationSound;
- (void) updateApplicationBadge;
- (void) worldsDidChange: (NSNotification *) notification;

@end

#pragma mark -

@implementation MUApplicationController

+ (void) initialize
{
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  NSMutableDictionary *initialValues = [NSMutableDictionary dictionary];
  NSValueTransformer *transformer = [[[FontNameToDisplayNameTransformer alloc] init] autorelease];
  NSFont *fixedPitchFont = [NSFont userFixedPitchFontOfSize: [NSFont smallSystemFontSize]];
  
  [NSValueTransformer setValueTransformer: transformer forName: @"FontNameToDisplayNameTransformer"];
  
  [defaults setObject: [NSArray array] forKey: MUPWorlds];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
  
  [initialValues setObject: [NSArchiver archivedDataWithRootObject: [NSColor blackColor]] forKey: MUPBackgroundColor];
  [initialValues setObject: [fixedPitchFont fontName] forKey: MUPFontName];
  [initialValues setObject: [NSNumber numberWithFloat: [fixedPitchFont pointSize]] forKey: MUPFontSize];
  [initialValues setObject: [NSArchiver archivedDataWithRootObject: [NSColor blueColor]] forKey: MUPLinkColor];
  [initialValues setObject: [NSArchiver archivedDataWithRootObject: [NSColor lightGrayColor]] forKey: MUPTextColor];
  [initialValues setObject: [NSArchiver archivedDataWithRootObject: [NSColor purpleColor]] forKey: MUPVisitedLinkColor];
  [initialValues setObject: [NSNumber numberWithBool: YES] forKey: MUPPlaySounds];
  [initialValues setObject: [NSNumber numberWithBool: NO] forKey: MUPPlayWhenActive];
  [initialValues setObject: @"Blow" forKey: MUPSoundChoice];
  
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: initialValues];
  
  [MUGrowlService defaultGrowlService];
}

- (void) awakeFromNib
{
  MUPortFormatter *newConnectionPortFormatter = [[[MUPortFormatter alloc] init] autorelease];
  
  [MUServices profileRegistry];
  [MUServices worldRegistry];
  
  connectionWindowControllers = [[NSMutableArray alloc] init];
  
  [self rebuildConnectionsMenuWithAutoconnect: YES];
  
  [newConnectionPortField setFormatter: newConnectionPortFormatter];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (colorPanelColorDidChange:)
                                               name: NSColorPanelColorDidChangeNotification
                                             object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (worldsDidChange:)
                                               name: MUWorldsDidChangeNotification
                                             object: nil];
  
  unreadCount = 0;
  dockBadge = [[CTBadge badgeWithColor: [NSColor blueColor] labelColor: [NSColor whiteColor]] retain];
  
  [self updateApplicationBadge];
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self name: nil object: nil];
  [dockBadge release];
  [connectionWindowControllers release];
  [profilesController release];
  [proxySettingsController release];
  [super dealloc];
}

- (BOOL) validateMenuItem: (NSMenuItem *) item
{
  if ([item action] == @selector (toggleUseProxy:))
    [item setState: ([[MUSocketFactory defaultFactory] useProxy] ? NSOnState : NSOffState)];
  return YES;
}

#pragma mark -
#pragma mark Actions

- (IBAction) chooseNewFont: (id) sender
{
  NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
  NSFont *font = [NSFont fontWithName: [values valueForKey: MUPFontName]
                                 size: [[values valueForKey: MUPFontSize] floatValue]];
  
  if (!font)
    font = [NSFont systemFontOfSize: [NSFont systemFontSize]];
  
  [[NSFontManager sharedFontManager] setSelectedFont: font isMultiple: NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

- (IBAction) connectToURL: (NSURL *) url
{
  if (!([[url scheme] isEqualToString: @"telnet"]
        || [[url scheme] isEqualToString: @"koan"]))
    return;
  
  MUWorld *world = [MUWorld worldWithHostname: [url host] port: [url port]];
  
  MUConnectionWindowController *controller = [[MUConnectionWindowController alloc] initWithWorld: world];
  
  [self openConnectionWithController: controller];
  
  [controller release];
}

- (IBAction) connectUsingPanelInformation: (id) sender
{
  MUWorld *world = [MUWorld worldWithHostname: [newConnectionHostnameField stringValue]
                                         port: [NSNumber numberWithInt: [newConnectionPortField intValue]]];;
  
  if ([newConnectionSaveWorldButton state] == NSOnState)
  	[[MUServices worldRegistry] insertObject: world inWorldsAtIndex: [[MUServices worldRegistry] count]];
  
  MUConnectionWindowController *controller = [[MUConnectionWindowController alloc] initWithWorld: world];
  
  [self openConnectionWithController: controller];
  [newConnectionPanel close];
  
  [controller release];
}

- (IBAction) openBugsWebPage: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://svn.thoughtlocker.net/trac/koan/"]];
}

- (IBAction) openNewConnectionPanel: (id) sender
{
  [newConnectionHostnameField setObjectValue: nil];
  [newConnectionPortField setObjectValue: nil];
  [newConnectionSaveWorldButton setState: NSOffState];
  [newConnectionPanel makeFirstResponder: newConnectionHostnameField];
  [newConnectionPanel makeKeyAndOrderFront: self];
}

- (IBAction) showAboutPanel: (id) sender;
{
  [NSApp orderFrontStandardAboutPanel: sender];
}

- (IBAction) showAcknowledgementsWindow: (id) sender
{
  if (!acknowledgementsController)
    acknowledgementsController = [[MUAcknowledgementsController alloc] init];
  if (acknowledgementsController)
    [acknowledgementsController showWindow: self];
}

- (IBAction) showPreferencesWindow: (id) sender
{
  [preferencesController showPreferencesWindow: sender];
}

- (IBAction) showProfilesPanel: (id) sender
{
  if (!profilesController)
    profilesController = [[MUProfilesController alloc] init];
  if (profilesController)
    [profilesController showWindow: self];
}

- (IBAction) showProxySettings: (id) sender
{
  if (!proxySettingsController)
    proxySettingsController = [[MUProxySettingsController alloc] init];
  if (proxySettingsController)
    [proxySettingsController showWindow: self];
}

- (IBAction) toggleUseProxy: (id) sender
{
  [[MUSocketFactory defaultFactory] toggleUseProxy];
}

#pragma mark -
#pragma mark NSApplication delegate

- (BOOL) application: (NSApplication *) application openFile: (NSString *) string
{
  return NO;
}

- (void) applicationDidBecomeActive: (NSNotification *) notification
{
  unreadCount = 0;
  [self updateApplicationBadge];
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication *) sender
{
  return NO;
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) application
{
  NSUInteger count = [connectionWindowControllers count];
  NSUInteger openConnections = 0;
  
  while (count--)
  {
    MUConnectionWindowController *controller = [connectionWindowControllers objectAtIndex: count];
    if (controller && [controller isConnectedOrConnecting])
      openConnections++;
  }
  
  if (openConnections > 0)
  {
    NSAlert *alert;
    NSInteger choice = NSAlertDefaultReturn;
    NSString *title = [NSString stringWithFormat:
      (openConnections == 1 ? _(MULConfirmQuitTitleSingular)
                            : _(MULConfirmQuitTitlePlural)),
      openConnections];
  
    if (openConnections > 1)
    {
      alert = [NSAlert alertWithMessageText: title
                              defaultButton: _(MULConfirm)
                            alternateButton: _(MULCancel)
                                otherButton: _(MULQuitImmediately)
                  informativeTextWithFormat: _(MULConfirmQuitMessage)];
    
      choice = [alert runModal];
      
      if (choice == NSAlertAlternateReturn)
        return NSTerminateCancel;
    }
    
    if (choice == NSAlertDefaultReturn)
    {
      [self recursivelyConfirmClose: YES];
      return NSTerminateLater;
    }
  }
  
  return NSTerminateNow;
}

- (void) applicationWillTerminate: (NSNotification *) notification
{
  [NSApp setApplicationIconImage: nil];
  
  [[MUSocketFactory defaultFactory] saveProxySettings];
}

#pragma mark -
#pragma mark MUConnectionWindowController delegate

- (void) connectionWindowControllerWillClose: (NSNotification *) notification
{
  MUConnectionWindowController *controller = [[[notification object] retain] autorelease];
  
  [connectionWindowControllers removeObject: controller];
}

- (void) connectionWindowControllerDidReceiveText: (NSNotification *) notification
{
  if ([self shouldPlayNotificationSound])
    [self playNotificationSound];
  
  if (![NSApp isActive])
  {
    [NSApp requestUserAttention: NSInformationalRequest];
    unreadCount++;
    [self updateApplicationBadge];
  }
}

@end

#pragma mark -

@implementation MUApplicationController (Private)

- (IBAction) changeFont: (id) sender
{
  [preferencesController changeFont];
}

- (void) colorPanelColorDidChange: (NSNotification *) notification
{
  [preferencesController colorPanelColorDidChange];
}

- (id) infoValueForKey: (NSString *) key
{
  if ([[[NSBundle mainBundle] localizedInfoDictionary] objectForKey: key])
    return [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey: key];
  
  return [[[NSBundle mainBundle] infoDictionary] objectForKey: key];
}

- (IBAction) openConnection: (id) sender
{
  MUConnectionWindowController *controller;
  MUProfile *profile = [sender representedObject];
  controller = [[MUConnectionWindowController alloc] initWithProfile: profile];
  
  [self openConnectionWithController: controller];
  
  [controller release];
}

- (void) openConnectionWithController: (MUConnectionWindowController *) controller
{
  [controller setDelegate: self];
  
  [connectionWindowControllers addObject: controller];
  [controller showWindow: self];
  [controller connect: nil];
}

- (void) playNotificationSound
{
  [[NSSound soundNamed: [[NSUserDefaults standardUserDefaults] stringForKey: MUPSoundChoice]] play];
}

- (void) rebuildConnectionsMenuWithAutoconnect: (BOOL) autoconnect
{
  MUWorldRegistry *registry = [MUServices worldRegistry];
  MUProfileRegistry *profiles = [MUServices profileRegistry];
  NSUInteger worldsCount = [registry count];
  NSUInteger menuCount = [openConnectionMenu numberOfItems];
  
  for (NSInteger menuItemIndex = menuCount - 1; menuItemIndex >= 0; menuItemIndex--)
  {
    [openConnectionMenu removeItemAtIndex: menuItemIndex];
  }
  
  for (unsigned i = 0; i < worldsCount; i++)
  {
    MUWorld *world = [registry worldAtIndex: i];
    MUProfile *profile = [profiles profileForWorld: world];
    NSArray *players = [world children];
    NSMenuItem *worldItem = [[NSMenuItem alloc] init];
    NSMenu *worldMenu = [[NSMenu alloc] initWithTitle: world.name];
    NSMenuItem *connectItem = [[NSMenuItem alloc] initWithTitle: _(MULConnectWithoutLogin)
                                                         action: @selector (openConnection:)
                                                  keyEquivalent: @""];
    NSUInteger playersCount = [players count];
    
    [connectItem setTarget: self];
    [connectItem setRepresentedObject: profile];
    
    if (autoconnect)
    {
      profile.world = world;
      if (profile.autoconnect)
        [self openConnection: connectItem];
    }
    
    for (unsigned j = 0; j < playersCount; j++)
    {
      MUPlayer *player = [players objectAtIndex: j];
      profile = [profiles profileForWorld: world player: player];
      
      SEL action = @selector (openConnection:);
      NSMenuItem *playerItem = [[NSMenuItem alloc] initWithTitle: player.name
                                                          action: action
                                                   keyEquivalent: @""];
      [playerItem setTarget: self];
      [playerItem setRepresentedObject: profile];
      
      if (autoconnect)
      {
        profile.world = world;
        profile.player = player;
        if (profile.autoconnect)
          [self openConnection: playerItem];
      }
      
      [worldMenu addItem: playerItem];
      [playerItem release];
    }
    
    if (playersCount > 0)
    {
      [worldMenu addItem: [NSMenuItem separatorItem]];
    }
    
    [worldMenu addItem: connectItem];
    [worldItem setTitle: world.name];
    [worldItem setSubmenu: worldMenu];
    [openConnectionMenu addItem: worldItem];
    [worldItem release];
    [worldMenu release];
    [connectItem release];
  }
}

- (void) recursivelyConfirmClose: (BOOL) cont
{
  if (cont)
  {
    for (MUConnectionWindowController *controller in connectionWindowControllers)
    {
      if ([controller isConnectedOrConnecting])
      {
        [controller confirmClose: @selector (recursivelyConfirmClose:)];
        return;
      }
    }
  }
  
  [NSApp replyToApplicationShouldTerminate: cont];
}

- (BOOL) shouldPlayNotificationSound
{
  return ([[NSUserDefaults standardUserDefaults] boolForKey: MUPPlaySounds]
          && (![NSApp isActive] || [[NSUserDefaults standardUserDefaults] boolForKey: MUPPlayWhenActive]));
}

- (void) updateApplicationBadge
{
  if (unreadCount == 0)
    [NSApp setApplicationIconImage: nil];
  else
    [dockBadge badgeApplicationDockIconWithValue: unreadCount insetX: 0.0 y: 0.0];
}

- (void) worldsDidChange: (NSNotification *) notification
{
  [self rebuildConnectionsMenuWithAutoconnect: NO];
}

@end
