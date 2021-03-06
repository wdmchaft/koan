//
// MUConstants.h
//
// Copyright (c) 2011 3James Software.
//

#import <Cocoa/Cocoa.h>

#pragma mark Application constants.

extern NSString *MUApplicationName;

#pragma mark User defaults constants.

extern NSString *MUPBackgroundColor;
extern NSString *MUPFontName;
extern NSString *MUPFontSize;
extern NSString *MUPLinkColor;
extern NSString *MUPTextColor;
extern NSString *MUPWorlds;
extern NSString *MUPProfiles;
extern NSString *MUPProfilesOutlineViewState;
extern NSString *MUPVisitedLinkColor;
extern NSString *MUPProxySettings;
extern NSString *MUPUseProxy;

extern NSString *MUPPlaySounds;
extern NSString *MUPPlayWhenActive;
extern NSString *MUPSoundChoice;

#pragma mark Notification constants.

extern NSString *MUConnectionWindowControllerWillCloseNotification;
extern NSString *MUConnectionWindowControllerDidReceiveTextNotification;
extern NSString *MUGlobalBackgroundColorDidChangeNotification;
extern NSString *MUGlobalFontDidChangeNotification;
extern NSString *MUGlobalLinkColorDidChangeNotification;
extern NSString *MUGlobalTextColorDidChangeNotification;
extern NSString *MUGlobalVisitedLinkColorDidChangeNotification;
extern NSString *MUWorldsDidChangeNotification;

extern NSString *MUReadBufferDidProvideStringNotification;

#pragma mark Toolbar item constants.

extern NSString *MUAddWorldToolbarItem;
extern NSString *MUAddPlayerToolbarItem;
extern NSString *MUEditSelectedRowToolbarItem;
extern NSString *MURemoveSelectedRowToolbarItem;
extern NSString *MUEditProfileForSelectedRowToolbarItem;
extern NSString *MUGoToURLToolbarItem;

#pragma mark Toolbar item localization constants.

extern NSString *MULAddWorld;
extern NSString *MULAddPlayer;
extern NSString *MULEditItem;
extern NSString *MULEditWorld;
extern NSString *MULEditPlayer;
extern NSString *MULGoToURL;
extern NSString *MULRemoveItem;
extern NSString *MULRemoveWorld;
extern NSString *MULRemovePlayer;
extern NSString *MULEditProfile;

#pragma mark Growl constants.

extern NSString *MUGConnectionOpened;
extern NSString *MUGConnectionClosed;
extern NSString *MUGConnectionClosedByServer;
extern NSString *MUGConnectionClosedByError;

#pragma mark Status message localization constants.

extern NSString *MULConnectionOpening;
extern NSString *MULConnectionOpen;
extern NSString *MULConnectionClosed;
extern NSString *MULConnectionClosedByServer;
extern NSString *MULConnectionClosedByError;

#pragma mark Alert panel localization constants.

extern NSString *MULOK;
extern NSString *MULConfirm;
extern NSString *MULQuitImmediately;
extern NSString *MULCancel;

extern NSString *MULConfirmCloseTitle;
extern NSString *MULConfirmCloseMessage;

extern NSString *MULConfirmQuitTitleSingular;
extern NSString *MULConfirmQuitTitlePlural;
extern NSString *MULConfirmQuitMessage;

#pragma mark Miscellaneous localization constants.

extern NSString *MULConnect;
extern NSString *MULDisconnect;

extern NSString *MULConnectWithoutLogin;

#pragma mark Miscellaneous other constants.

extern NSString *MUInsertionIndex;
extern NSString *MUInsertionWorld;

#pragma mark ANSI parsing constants

extern NSString *MUANSIForegroundColorAttributeName;
extern NSString *MUANSIBackgroundColorAttributeName;
