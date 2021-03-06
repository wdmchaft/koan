//
// MUProxySettingsController.m
//
// Copyright (c) 2011 3James Software.
//

#import "MUProxySettingsController.h"
#import "MUSocketFactory.h"
#import "MUPortFormatter.h"
#import "MUProxySettings.h"

@implementation MUProxySettingsController

- (id) init
{
  self = [super initWithWindowNibName: @"MUProxySettings"];
  
  return self;
}

- (void) awakeFromNib
{
  MUPortFormatter *portFormatter = [[[MUPortFormatter alloc] init] autorelease];
  
  [portField setFormatter: portFormatter];
}

- (MUProxySettings *) proxySettings
{
  return [[MUSocketFactory defaultFactory] proxySettings];
}

@end
