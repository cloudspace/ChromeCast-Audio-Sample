//
//  ChromecastDeviceController.m
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import "CastMiniController.h"
#import "CastIconButton.h"
#import "CastViewController.h"
#import "ChromecastDeviceController.h"
#import "DeviceTableViewController.h"
#import "SimpleImageFetcher.h"

#import "Media.h"
#import "MediaListModel.h"

NSString * const kCastComponentPosterURL = @"castComponentPosterURL";
static NSString * const kDeviceTableViewController = @"deviceTableViewController";
static NSString * const kCastViewController = @"castViewController";

@interface ChromecastDeviceController () <GCKLoggerDelegate, CastMiniControllerDelegate> {
  dispatch_queue_t _queue;
}

@property GCKMediaControlChannel *mediaControlChannel;
@property GCKApplicationMetadata *applicationMetadata;
@property GCKDevice *selectedDevice;

@property bool deviceMuted;
@property bool isReconnecting;

@property (nonatomic, readwrite) UIStoryboard *storyboard;
@property (nonatomic) CastMiniController *castMiniController;
@property (nonatomic) CastIconBarButtonItem *castIconButton;

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic) BOOL manageToolbar;

@property (nonatomic) NSString *lastContentID;
@property (nonatomic) NSTimeInterval lastPosition;

@end

@implementation ChromecastDeviceController

+ (instancetype)sharedInstance {
  static dispatch_once_t p = 0;
  __strong static id _sharedDeviceController = nil;

  dispatch_once(&p, ^{
    _sharedDeviceController = [[self alloc] init];
  });

  return _sharedDeviceController;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.isReconnecting = NO;

    // Initialize device scanner
    self.deviceScanner = [[GCKDeviceScanner alloc] init];
    self.deviceScanner.passiveScan = YES;

    // Initialize UI controls for navigation bar and tool bar.
    [self initControls];

    // Load the storyboard for the Cast component UI.
    self.storyboard = [UIStoryboard storyboardWithName:@"CastComponents" bundle:nil];

    // Queue used for loading thumbnails.
    _queue = dispatch_queue_create("com.na.sample.Chromecast", NULL);

  }
  return self;
}

- (void)setApplicationID:(NSString *)applicationID {
  _applicationID = applicationID;

  GCKFilterCriteria *filterCriteria = [[GCKFilterCriteria alloc] init];
  filterCriteria = [GCKFilterCriteria criteriaForAvailableApplicationWithID:applicationID];

  self.deviceScanner.filterCriteria = filterCriteria;

  [self performScan:YES];
}

- (BOOL)isConnected {
  return self.deviceManager.applicationConnectionState == GCKConnectionStateConnected;
}

- (BOOL)isPlayingMedia {
  return  self.deviceManager.connectionState == GCKConnectionStateConnected &&
          self.mediaControlChannel && self.mediaControlChannel.mediaStatus &&
          ( self.playerState == GCKMediaPlayerStatePlaying ||
            self.playerState == GCKMediaPlayerStatePaused ||
            self.playerState == GCKMediaPlayerStateBuffering);
}

- (BOOL)isPaused {
  return self.deviceManager.isConnected && self.mediaControlChannel &&
  self.mediaControlChannel.mediaStatus && self.playerState == GCKMediaPlayerStatePaused;
}

- (void)performScan:(BOOL)start {
  if (start) {
    NSLog(@"Start Scan");
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
  } else {
    NSLog(@"Stop Scan");
    [self.deviceScanner stopScan];
    [self.deviceScanner removeListener:self];
  }
}

- (void)connectToDevice:(GCKDevice *)device {
  NSLog(@"Device address: %@:%d", device.ipAddress, (unsigned int) device.servicePort);
  self.selectedDevice = device;

  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  NSString *appIdentifier = [info objectForKey:@"CFBundleIdentifier"];
  self.deviceManager =
      [[GCKDeviceManager alloc] initWithDevice:self.selectedDevice clientPackageName:appIdentifier];
  self.deviceManager.delegate = self;
  [self.deviceManager connect];

  // Start animating the cast connect images.
  self.castIconButton.status = CIBCastConnecting;
}

- (void)disconnectFromDevice {
  NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
  // We're not going to stop the applicaton in case we're not the last client.
  [self.deviceManager leaveApplication];
  // If you want to force application to stop, uncomment below.
  //[self.deviceManager stopApplication];
  [self.deviceManager disconnect];
}

- (void)updateToolbarForViewController:(UIViewController *)viewController {
  [self.castMiniController updateToolbarStateIn:viewController
                            forMediaInformation:self.mediaInformation
                                    playerState:self.playerState];
}

- (void)updateStatsFromDevice {
  if (self.isConnected && self.mediaControlChannel && self.mediaControlChannel.mediaStatus) {
    _streamPosition = [self.mediaControlChannel approximateStreamPosition];
    _streamDuration = self.mediaControlChannel.mediaStatus.mediaInformation.streamDuration;

    _playerState = self.mediaControlChannel.mediaStatus.playerState;
    _mediaInformation = self.mediaControlChannel.mediaStatus.mediaInformation;
    if (!self.selectedTrackByIdentifier) {
      [self zeroSelectedTracks];
    }

    self.lastPosition = _streamPosition;
    self.lastContentID = _mediaInformation.contentID;
  }
}

- (void)setDeviceVolume:(float)deviceVolume {
  [self.deviceManager setVolume:deviceVolume];
}

- (void)setPlaybackPercent:(float)newPercent {
  newPercent = MAX(MIN(1.0, newPercent), 0.0);

  NSTimeInterval newTime = newPercent * _streamDuration;
  if (_streamDuration > 0 && self.isConnected) {
    [self.mediaControlChannel seekToTimeInterval:newTime];
  }
}

- (void)pauseCastMedia:(BOOL)shouldPause {
  if (self.isConnected && self.mediaControlChannel && self.mediaControlChannel.mediaStatus) {
    if (shouldPause) {
      [self.mediaControlChannel pause];
    } else {
      [self.mediaControlChannel play];
    }
  }
}

- (void)stopCastMedia {
  if (self.isConnected && self.mediaControlChannel && self.mediaControlChannel.mediaStatus) {
    NSLog(@"Telling cast media control channel to stop");
    [self.mediaControlChannel stop];
  }
}

- (void)manageViewController:(UIViewController *)controller icon:(BOOL)icon toolbar:(BOOL)toolbar {
  if (!controller.navigationItem) {
    NSLog(@"View Controller must have navigation item for auto-icon management.");
    return;
  }
  self.viewController = controller;
  self.manageToolbar = toolbar;
  if (icon) {
    controller.navigationItem.rightBarButtonItem = _castIconButton;
  }
  if (self.manageToolbar) {
    [self updateToolbarForViewController:self.viewController];
  }
}

- (void)enableLogging {
  [[GCKLogger sharedInstance] setDelegate:self];
}

- (CastViewController *)castViewControllerForMedia:(GCKMediaInformation *)media withStartingTime:(NSTimeInterval)startTime selectedMedia:(Media*)selectedMedia mediaList:(MediaListModel*)mediaList {
  CastViewController *vc = [_storyboard instantiateViewControllerWithIdentifier:kCastViewController];
  [vc setMediaToPlay:media withStartingTime:startTime selectedMedia:selectedMedia mediaList:mediaList];
  return vc;
}

- (void)displayCurrentlyPlayingMedia {
  if (self.viewController && self.manageToolbar) {
    CastViewController *vc = [_storyboard instantiateViewControllerWithIdentifier:kCastViewController];
    [vc setMediaToPlay:self.mediaInformation];
    [self.viewController.navigationController pushViewController:vc animated:YES];
  }
}

- (NSTimeInterval)streamPositionForPreviouslyCastMedia:(NSString *)contentID {
  if ([contentID isEqualToString:_lastContentID]) {
    return _lastPosition;
  }
  return 0;
}

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {

  if(!self.isReconnecting) {
    [self.deviceManager launchApplication:_applicationID];
  } else {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* lastSessionID = [defaults valueForKey:@"lastSessionID"];
    [self.deviceManager joinApplication:_applicationID sessionID:lastSessionID];
  }
  [self updateCastIconButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata
                      sessionID:(NSString *)sessionID
            launchedApplication:(BOOL)launchedApplication {

  self.isReconnecting = NO;
  self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
  self.mediaControlChannel.delegate = self;
  [self.deviceManager addChannel:self.mediaControlChannel];
  [self.mediaControlChannel requestStatus];

  self.applicationMetadata = applicationMetadata;
  [self updateCastIconButtonStates];

  if ([self.delegate respondsToSelector:@selector(didConnectToDevice:)]) {
    [self.delegate didConnectToDevice:self.selectedDevice];
  }

  if (self.viewController && self.manageToolbar) {
    [self updateToolbarForViewController:self.viewController];
  }

  // Store sessionID in case of restart
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:sessionID forKey:@"lastSessionID"];
  [defaults setObject:[self.selectedDevice deviceID] forKey:@"lastDeviceID"];
  [defaults synchronize];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
  didFailToConnectToApplicationWithError:(NSError *)error {
  if(self.isReconnecting && [error code] == GCKErrorCodeApplicationNotRunning) {
    // Expected error when unable to reconnect to previous session after another
    // application has been running
    self.isReconnecting = false;
  } else {
    [self showError:error.description];
  }

  [self updateCastIconButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectWithError:(GCKError *)error {
  [self showError:error.description];

  [self deviceDisconnectedForgetDevice:YES];
  [self updateCastIconButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(GCKError *)error {
  NSLog(@"Received notification that device disconnected");

  // Network errors are displayed in the suspend code.
  if (error && error.code != GCKErrorCodeNetworkError) {
    [self showError:error.description];
  }

  // Forget the device except when the error is a connectivity related, such a WiFi problem.
  [self deviceDisconnectedForgetDevice:![self isRecoverableError:error]];
  [self updateCastIconButtonStates];

}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didDisconnectFromApplicationWithError:(NSError *)error {
  NSLog(@"Received notification that app disconnected");

  if (error) {
    NSLog(@"Application disconnected with error: %@", error);
  }

  // Forget the device except when the error is a connectivity related, such a WiFi problem.
  [self deviceDisconnectedForgetDevice:![self isRecoverableError:error]];
  [self updateCastIconButtonStates];
}

- (BOOL)isRecoverableError:(NSError *)error {
  if (!error) {
    return NO;
  }

  return (error.code == GCKErrorCodeNetworkError ||
          error.code == GCKErrorCodeTimeout ||
          error.code == GCKErrorCodeAppDidEnterBackground);
}

- (void)deviceDisconnectedForgetDevice:(BOOL)clear {
  self.mediaControlChannel = nil;
  _playerState = 0;
  _mediaInformation = nil;
  self.selectedDevice = nil;

  if ([self.delegate respondsToSelector:@selector(didDisconnect)]) {
    [self.delegate didDisconnect];
  }

  if (self.viewController && self.manageToolbar) {
    [self updateToolbarForViewController:self.viewController];
  }

  if (clear) {
    [self clearPreviousSession];
  }
}

- (void)clearPreviousSession {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:@"lastDeviceID"];
  [defaults synchronize];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didReceiveApplicationMetadata:(GCKApplicationMetadata *)applicationMetadata {
  self.applicationMetadata = applicationMetadata;
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    volumeDidChangeToLevel:(float)volumeLevel
                   isMuted:(BOOL)isMuted {
  _deviceVolume = volumeLevel;
  self.deviceMuted = isMuted;

  // Fire off a notification, so no matter what controller we are in, we can show the volume
  // slider
  [[NSNotificationCenter defaultCenter] postNotificationName:@"Volume changed" object:self];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didSuspendConnectionWithReason:(GCKConnectionSuspendReason)reason {
  if (reason == GCKConnectionSuspendReasonAppBackgrounded) {
    NSLog(@"Connection Suspended: App Backgrounded");
  } else {
    NSLog(@"Connection Suspended: Network disconnected. Expecting reconnect.");
  }
}

- (void)deviceManagerDidResumeConnection:(GCKDeviceManager *)deviceManager
                     rejoinedApplication:(BOOL)rejoinedApplication {
  NSLog(@"Connection Resumed. App Rejoined: %@", rejoinedApplication ? @"YES" : @"NO");
  [self updateCastIconButtonStates];
}

#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device {
  NSLog(@"device found - %@", device.ipAddress);

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString* lastDeviceID = [defaults objectForKey:@"lastDeviceID"];
  if(lastDeviceID != nil && [[device deviceID] isEqualToString:lastDeviceID]){
    self.isReconnecting = true;
    [self connectToDevice:device];
  }

  if ([self.delegate respondsToSelector:@selector(didDiscoverDeviceOnNetwork)]) {
    [self.delegate didDiscoverDeviceOnNetwork];
  }

  // Always update after notifying the delegate.
  [self updateCastIconButtonStates];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
  NSLog(@"device went offline - %@", device.friendlyName);
  [self updateCastIconButtonStates];
}

#pragma mark - GCKMediaControlChannelDelegate methods

- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
    didCompleteLoadWithSessionID:(NSInteger)sessionID {
  _mediaControlChannel = mediaControlChannel;
}

- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel {
  [self updateStatsFromDevice];
  NSLog(@"Media control channel status changed");
  _mediaControlChannel = mediaControlChannel;
  [self updateTrackSelectionFromActiveTracks:_mediaControlChannel.mediaStatus.activeTrackIDs];
  if ([self.delegate respondsToSelector:@selector(didReceiveMediaStateChange)]) {
    [self.delegate didReceiveMediaStateChange];
  }
  if (self.viewController && self.manageToolbar) {
    [self updateToolbarForViewController:self.viewController];
  }
}

- (void)mediaControlChannelDidUpdateMetadata:(GCKMediaControlChannel *)mediaControlChannel {
  NSLog(@"Media control channel metadata changed");
  _mediaControlChannel = mediaControlChannel;
  [self updateStatsFromDevice];

  if ([self.delegate respondsToSelector:@selector(didReceiveMediaStateChange)]) {
    [self.delegate didReceiveMediaStateChange];
  }
}

- (BOOL)loadMedia:(GCKMediaInformation *)media
            startTime:(NSTimeInterval)startTime
         autoPlay:(BOOL)autoPlay {
  if (!self.deviceManager || self.deviceManager.connectionState != GCKConnectionStateConnected ) {
    return NO;
  }

  // Reset selected tracks.
  self.selectedTrackByIdentifier = nil;

  [self.mediaControlChannel loadMedia:media autoplay:autoPlay playPosition:startTime];

  return YES;
}

# pragma mark - GCKMediaTextTrackStyle

- (GCKMediaTextTrackStyle *)textTrackStyle {
  if (!_textTrackStyle) {
    // createDefault will use the system captions style via the MediaAccessibility framework
    // in iOS 7 and above. For apps which support iOS 6 you may want to implement a Settings
    // bundle and customise a GCKMediaTextTrackStyle manually on those systems.
    _textTrackStyle = [GCKMediaTextTrackStyle createDefault];
  }
  return _textTrackStyle;
}

#pragma mark - implementation

- (void)showError:(NSString *)errorDescription {
  NSLog(@"Received error: %@", errorDescription);
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cast Error", nil)
                                                  message:NSLocalizedString(@"An error occurred. Make sure your Chromecast is powered up and connected to the network.", nil)
                                                 delegate:nil
                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                        otherButtonTitles:nil];
  [alert show];
}

- (NSString *)deviceName {
  if (self.selectedDevice == nil)
    return @"";
  return self.selectedDevice.friendlyName;
}

- (void)initControls {
  self.castIconButton = [CastIconBarButtonItem barButtonItemWithTarget:self
                                                          selector:@selector(chooseDevice:)];
  self.castMiniController = [[CastMiniController alloc] initWithDelegate:self];
}

- (void)chooseDevice:(id)sender {
  BOOL showPicker = YES;
  if ([self.delegate respondsToSelector:@selector(shouldDisplayModalDeviceController)]) {
    showPicker = [_delegate shouldDisplayModalDeviceController];
  }
  if (self.viewController && showPicker) {
    // If we are managing the display, fire the device picker.
    UINavigationController *dtvc = (UINavigationController *)[_storyboard instantiateViewControllerWithIdentifier:kDeviceTableViewController];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
      dtvc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    // This is a little unpleasant, but is our way of getting a handle back so the device
    // table can dismiss itself. The nicer method would be to introduce a protocol so that
    // the client could dismiss it, but since we're trying to minimise the work the Media side
    // of the app has to do, we'll use this for now. One option may be to have the protocol on
    // the ChromecastDeviceController.
    ((DeviceTableViewController *)dtvc.viewControllers[0]).viewController = self.viewController;
    [self.viewController presentViewController:dtvc animated:YES completion:nil];
  }
}

- (void)updateCastIconButtonStates {
  if (self.deviceScanner.devices.count == 0) {
    _castIconButton.status = CIBCastUnavailable;
  } else if (self.deviceManager.applicationConnectionState == GCKConnectionStateConnecting) {
    _castIconButton.status = CIBCastConnecting;
  } else if (self.deviceManager.applicationConnectionState == GCKConnectionStateConnected) {
    _castIconButton.status = CIBCastConnected;
  } else {
    _castIconButton.status = CIBCastAvailable;
  }
}

# pragma mark - Tracks management

- (void)updateActiveTracks {
  NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:[self.selectedTrackByIdentifier count]];
  NSEnumerator *enumerator = [self.selectedTrackByIdentifier keyEnumerator];
  NSNumber *key;
  while ((key = [enumerator nextObject])) {
    if ([[self.selectedTrackByIdentifier objectForKey:key] boolValue]) {
      [tracks addObject:key];
    }
  }
  [self.mediaControlChannel setActiveTrackIDs:tracks];
}

- (void)updateTrackSelectionFromActiveTracks:(NSArray *)activeTracks {
  if ([_mediaControlChannel.mediaStatus.activeTrackIDs count] == 0) {
    [self zeroSelectedTracks];
  }

  NSEnumerator *enumerator = [self.selectedTrackByIdentifier keyEnumerator];
  NSNumber *key;
  while ((key = [enumerator nextObject])) {
    [self.selectedTrackByIdentifier
        setObject:[NSNumber numberWithBool:[activeTracks containsObject:key]]
           forKey:key];
    }
}

- (void)zeroSelectedTracks {
  // Disable tracks.
  self.selectedTrackByIdentifier =
      [NSMutableDictionary dictionaryWithCapacity:[self.mediaInformation.mediaTracks count]];
  NSNumber *nope = [NSNumber numberWithBool:NO];
  for (GCKMediaTrack *track in self.mediaInformation.mediaTracks) {
    [self.selectedTrackByIdentifier setObject:nope
                                       forKey:[NSNumber numberWithInteger:track.identifier]];
  }
}

#pragma mark - GCKLoggerDelegate implementation

- (void)logFromFunction:(const char *)function message:(NSString *)message {
  // Send SDK’s log messages directly to the console, as an example.
  NSLog(@"%s  %@", function, message);
}

@end
