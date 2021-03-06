//
// MUProfilesController.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUProfilesController.h"
#import "MUPortFormatter.h"
#import "MUProfile.h"
#import "MUProfilesSection.h"
#import "MUSection.h"
#import "MUServices.h"

#import "ImageAndTextCell.h"

@interface MUProfilesController (Private)

- (void) applicationWillTerminate: (NSNotification *) notification;

#if 0
- (IBAction) changeFont: (id) sender;
- (void) colorPanelColorDidChange: (NSNotification *) notification;
- (void) globalBackgroundColorDidChange: (NSNotification *) notification;
- (void) globalFontDidChange: (NSNotification *) notification;
- (void) globalLinkColorDidChange: (NSNotification *) notification;
- (void) globalTextColorDidChange: (NSNotification *) notification;
- (void) globalVisitedLinkColorDidChange: (NSNotification *) notification;
#endif

- (void) registerForNotifications;

@end

#pragma mark -

@interface MUProfilesController (TreeController)

- (void) expandProfilesOutlineView;
- (void) populateProfilesFromWorldRegistry;
- (void) populateProfilesTree;
- (void) saveProfilesOutlineViewState;

@end

#pragma mark -

@implementation MUProfilesController

@synthesize profilesTreeArray;

- (id) init
{
  if (!(self = [super initWithWindowNibName: @"MUProfiles"]))
    return nil;
  
  profilesTreeArray = [[NSMutableArray alloc] init];
  profilesExpandedItems = [[NSMutableArray alloc] init];
  
  return self;
}

- (void) awakeFromNib
{
  // MUPortFormatter *worldPortFormatter = [[[MUPortFormatter alloc] init] autorelease];
  
  // FIXME: [worldPortField setFormatter: worldPortFormatter];
  
  editingFont = nil;
  
  backgroundColorActive = NO;
  linkColorActive = NO;
  textColorActive = NO;
  visitedLinkColorActive = NO;
  
  [self populateProfilesTree];
  
  [self registerForNotifications];
}

- (void) dealloc
{
  [profilesTreeArray release];
  [profilesExpandedItems release];
  [super dealloc];
}

#pragma mark -
#pragma mark Actions

- (IBAction) chooseNewFont: (id) sender
{
  NSDictionary *values = [[NSUserDefaultsController sharedUserDefaultsController] values];
  NSString *fontName = [values valueForKey: MUPFontName];
  int fontSize = [[values valueForKey: MUPFontSize] floatValue];
  NSFont *font = [NSFont fontWithName: fontName size: fontSize];
  
  if (font == nil)
  {
    font = [NSFont systemFontOfSize: [NSFont systemFontSize]];
  }
  
  [[NSFontManager sharedFontManager] setSelectedFont: font isMultiple: NO];
  [[NSFontManager sharedFontManager] orderFrontFontPanel: self];
}

- (IBAction) goToWorldURL: (id) sender
{
  return;
}

#pragma mark -
#pragma mark NSOutlineView data source

// I tried implementing this the recommended way, but in 10.6 at least there seems
// to be no functional way of getting it working.
//
// In particular, this doesn't seem to work:
//   <http://blog.pioneeringsoftware.co.uk/2008/09/10/outline-view-tree-controller-and-itemforpersistentobject>
//
// Therefore, I'm expanding the tree manually. I'm using the dataSource methods and
// calling them manually; the "saving" part works, but the "restoring" part doesn't.
// The outlineView:itemForPersistentObject: method *does* work, it's just evidently
// not getting called at the right times.

- (id) outlineView: (NSOutlineView *) outlineView itemForPersistentObject: (id) object
{
  if (object && [object isKindOfClass: [NSString class]])
  {
    // Iterate all the items. This is not straightforward because the outline
    // view items are nested. So you cannot just iterate the rows. Rows
    // correspond to root nodes only. The outline view interface does not
    // provide any means to query the hidden children within each collapsed row
    // either. However, the root nodes do respond to -childNodes. That makes it
    // possible to walk the tree.
    
    NSMutableArray *items = [NSMutableArray array];
    NSUInteger rows = [outlineView numberOfRows];
    
    for (NSUInteger i = 0; i < rows; i++)
    {
      [items addObject: [outlineView itemAtRow: i]];
    }
    
    for (NSUInteger i = 0; i < [items count]; i++)
    {
      NSTreeNode *shadowObject = [items objectAtIndex: i];
      MUTreeNode *node = [shadowObject representedObject];
      
      if ([node isKindOfClass: [MUWorld class]])
        if ([((MUWorld *) node).uniqueIdentifier isEqualToString: object])
          return shadowObject;
      
      [items addObjectsFromArray: [shadowObject childNodes]];
    }
  }
  
  return nil;
}

- (id) outlineView: (NSOutlineView *) outlineView persistentObjectForItem: (id) item
{
  id node = [(NSTreeNode *) item representedObject];
  
  if ([node isKindOfClass: [MUWorld class]])
  	return ((MUWorld *) node).uniqueIdentifier;
  else
  	return nil;
}

#pragma mark -
#pragma mark NSOutlineView delegate

- (BOOL) outlineView: (NSOutlineView *) outlineView isGroupItem: (id) item
{
  return [[item representedObject] isKindOfClass: [MUSection class]] ? YES : NO;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldCollapseItem: (id) item
{
  return [self outlineView: outlineView isGroupItem: item] ? NO : YES;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldEditTableColumn: (NSTableColumn *) tableColumn item: (id) item
{
  return NO;
}

- (BOOL) outlineView: (NSOutlineView *) outlineView shouldSelectItem: (id) item
{
  return [self outlineView: outlineView isGroupItem: item] ? NO : YES;
}

- (void) outlineView: (NSOutlineView *) outlineView willDisplayCell: (id) cell forTableColumn: (NSTableColumn *) tableColumn item: (id) item
{
  if ([cell isKindOfClass: [ImageAndTextCell class]])
  {
    if ([self outlineView: outlineView isGroupItem: item])
      [cell setImage: nil];
    else
    {
      id representedObject = [(NSTreeNode *) item representedObject];
      
      if ([representedObject isKindOfClass: [MUWorld class]])
      {
        NSImage *worldImage = [[NSImage imageNamed: NSImageNameNetwork] retain];
        [worldImage setSize: NSMakeSize (16, 16)];
        [cell setImage: worldImage];
        [worldImage release];
      }
      else if ([representedObject isKindOfClass: [MUPlayer class]])
      {
        NSImage *playerImage = [[NSImage imageNamed: NSImageNameUser] retain];
        [playerImage setSize: NSMakeSize (16, 16)];
        [cell setImage: playerImage];
        [playerImage release];
      }
      else
      {
        NSImage *folderImage = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode (kGenericFolderIcon)];
        [folderImage setSize: NSMakeSize (16, 16)];
        [cell setImage: folderImage];
      }
    }
  }
}

- (void) outlineView: (NSOutlineView *) outlineView willDisplayOutlineCell: (id) cell forTableColumn: (NSTableColumn *) tableColumn item: (id) item
{
  if ([self outlineView: outlineView isGroupItem: item])
    [cell setTransparent: YES];
  else
    [cell setTransparent: NO];
}

- (void) outlineViewItemWillCollapse: (NSNotification *) notification
{
  id persistentObject = [self outlineView: profilesOutlineView persistentObjectForItem: [[notification userInfo] objectForKey: @"NSObject"]];
  
  if (persistentObject)
    [profilesExpandedItems removeObject: persistentObject];
}

- (void) outlineViewItemWillExpand: (NSNotification *) notification
{
  id persistentObject = [self outlineView: profilesOutlineView persistentObjectForItem: [[notification userInfo] objectForKey: @"NSObject"]];
  
  if (persistentObject)
    [profilesExpandedItems addObject: persistentObject];
}

- (void) outlineViewSelectionDidChange: (NSNotification *) notification
{
  return;
}

#pragma mark -
#pragma mark NSWindow delegate

- (void) windowDidLoad
{
  [self expandProfilesOutlineView];
}

- (void) windowWillClose: (NSNotification *) notification
{
  [self saveProfilesOutlineViewState];
}

@end

#pragma mark -

@implementation MUProfilesController (Private)

- (void) applicationWillTerminate: (NSNotification *) notification
{
  [self saveProfilesOutlineViewState];
}

#if 0

- (IBAction) changeFont: (id) sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFont *selectedFont = [fontManager selectedFont];
  NSFont *panelFont;
  
  if (selectedFont == nil)
  {
    selectedFont = [NSFont systemFontOfSize: [NSFont systemFontSize]];
  }
  
  panelFont = [fontManager convertFont: selectedFont];
  
  [profileFontUseGlobalButton setState: NSOffState];
  [profileFontField setStringValue: [panelFont fullDisplayName]];
  editingFont = [panelFont copy];
}

- (void) colorPanelColorDidChange: (NSNotification *) notification
{
  if ([profileBackgroundColorWell isActive])
  {
    if (backgroundColorActive)
      [profileBackgroundColorUseGlobalButton setState: NSOffState];
    else
    {
      backgroundColorActive = YES;
      linkColorActive = NO;
      textColorActive = NO;
      visitedLinkColorActive = NO;
    }
  }
  else if ([profileLinkColorWell isActive])
  {
    if (linkColorActive)
      [profileLinkColorUseGlobalButton setState: NSOffState];
    else
    {
      backgroundColorActive = NO;
      linkColorActive = YES;
      textColorActive = NO;
      visitedLinkColorActive = NO;
    }
  }
  else if ([profileTextColorWell isActive])
  {
    if (textColorActive)
      [profileTextColorUseGlobalButton setState: NSOffState];
    else
    {
      backgroundColorActive = NO;
      linkColorActive = NO;
      textColorActive = YES;
      visitedLinkColorActive = NO;
    }
  }
  else if ([profileVisitedLinkColorWell isActive])
  {
    if (visitedLinkColorActive)
      [profileVisitedLinkColorUseGlobalButton setState: NSOffState];
    else
    {
      backgroundColorActive = NO;
      linkColorActive = NO;
      textColorActive = NO;
      visitedLinkColorActive = YES;
    }
  }
  else
  {
    backgroundColorActive = NO;
    linkColorActive = NO;
    textColorActive = NO;
    visitedLinkColorActive = NO;
  }
}

- (void) globalBackgroundColorDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileBackgroundColorUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    NSData *colorData = [[defaults values] valueForKey: MUPBackgroundColor];
    
    [profileBackgroundColorWell setColor: [NSUnarchiver unarchiveObjectWithData: colorData]];
  }
}

- (void) globalFontDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileFontUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
  	NSString *fontName = [[defaults values] valueForKey: MUPFontName];
  	NSNumber *fontSize = [[defaults values] valueForKey: MUPFontSize];
    
    [editingFont release];
    editingFont = nil;
    
  	[profileFontField setStringValue: [[NSFont fontWithName: fontName size: [fontSize floatValue]] fullDisplayName]];
  }
}

- (void) globalLinkColorDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileBackgroundColorUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    NSData *colorData = [[defaults values] valueForKey: MUPLinkColor];
    
    [profileLinkColorWell setColor: [NSUnarchiver unarchiveObjectWithData: colorData]];
  }
}

- (void) globalTextColorDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileTextColorUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    NSData *colorData = [[defaults values] valueForKey: MUPTextColor];
    
    [profileTextColorWell setColor: [NSUnarchiver unarchiveObjectWithData: colorData]];
  }
}

- (void) globalVisitedLinkColorDidChange: (NSNotification *) notification
{
  if (editingProfile && [profileBackgroundColorUseGlobalButton state] == NSOnState)
  {
    NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
    NSData *colorData = [[defaults values] valueForKey: MUPVisitedLinkColor];
    
    [profileVisitedLinkColorWell setColor: [NSUnarchiver unarchiveObjectWithData: colorData]];
  }
}

#endif

- (void) registerForNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (applicationWillTerminate:)
                                               name: NSApplicationWillTerminateNotification
                                             object: NSApp];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector (colorPanelColorDidChange:)
                                               name: NSColorPanelColorDidChangeNotification
                                             object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalBackgroundColorDidChange:)
  																						 name: MUGlobalBackgroundColorDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalFontDidChange:)
  																						 name: MUGlobalFontDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalLinkColorDidChange:)
  																						 name: MUGlobalLinkColorDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalTextColorDidChange:)
  																						 name: MUGlobalTextColorDidChangeNotification
  																					 object: nil];
  
  [[NSNotificationCenter defaultCenter] addObserver: self
  																				 selector: @selector (globalVisitedLinkColorDidChange:)
  																						 name: MUGlobalVisitedLinkColorDidChangeNotification
  																					 object: nil];
}

@end

#pragma mark -

@implementation MUProfilesController (TreeController)

- (void) expandProfilesOutlineView
{
  [profilesOutlineView collapseItem: nil collapseChildren: YES];
  
  for (NSUInteger i = 0; i < [profilesOutlineView numberOfRows]; i++)
  {
    NSTreeNode *node = [profilesOutlineView itemAtRow: i];
    
    if ([((MUTreeNode *) [node representedObject]) isKindOfClass: [MUSection class]])
      [profilesOutlineView expandItem: node];
  }
  
  NSArray *stateArray = [[NSUserDefaults standardUserDefaults] arrayForKey: MUPProfilesOutlineViewState];
  
  if (!stateArray)
    return;
  
  for (id stateObject in stateArray)
    [profilesOutlineView expandItem: [self outlineView: profilesOutlineView itemForPersistentObject: stateObject]];
}

- (void) populateProfilesFromWorldRegistry
{
  MUProfilesSection *profilesSection = [[MUProfilesSection alloc] initWithName: @"PROFILES"];
  
  [self willChangeValueForKey: @"profilesTreeArray"];
  [profilesTreeArray addObject: profilesSection];
  [self didChangeValueForKey: @"profilesTreeArray"];
}

- (void) populateProfilesTree
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self populateProfilesFromWorldRegistry];
	
	[pool release];
}

- (void) saveProfilesOutlineViewState
{
  [[NSUserDefaults standardUserDefaults] setObject: profilesExpandedItems forKey: MUPProfilesOutlineViewState];
}

- (void) applicationWillTerminate: (NSNotification *) notification
{
  [self saveProfilesOutlineViewState];
}

@end
