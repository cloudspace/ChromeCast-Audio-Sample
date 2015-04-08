//
//  ChromecastDeviceController.h
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import <GoogleCast/GoogleCast.h>
#import <Foundation/Foundation.h>

extern NSString * const kCastComponentPosterURL;

@protocol ChromecastControllerDelegate<NSObject>

@optional
- (void)didDiscoverDeviceOnNetwork;
- (void)didConnectToDevice:(GCKDevice*)device;
- (void)didDisconnect;
- (void)didReceiveMediaStateChange;
- (BOOL)shouldDisplayModalDeviceController;

@end

@interface ChromecastDeviceController : NSObject <GCKDeviceScannerListener, GCKDeviceManagerDelegate, GCKMediaControlChannelDelegate>

@property (nonatomic, strong) NSString *applicationID;
@property (nonatomic, strong) GCKDeviceScanner* deviceScanner;
@property (nonatomic, strong) GCKDeviceManager* deviceManager;
@property (nonatomic, strong) NSMutableDictionary *selectedTrackByIdentifier;
@property (nonatomic, strong) GCKMediaTextTrackStyle *textTrackStyle;
@property (nonatomic, assign) float deviceVolume;

@property (nonatomic, assign) id<ChromecastControllerDelegate> delegate;

@property (nonatomic, strong, readonly) NSString* deviceName;
@property (nonatomic, strong, readonly) UIStoryboard *storyboard;
@property (nonatomic, strong, readonly) GCKMediaInformation* mediaInformation;
@property (nonatomic, assign, readonly) GCKMediaPlayerState playerState;
@property (nonatomic, assign, readonly) NSTimeInterval streamDuration;
@property (nonatomic, assign, readonly) NSTimeInterval streamPosition;


+ (instancetype)sharedInstance;

- (void)updateToolbarForViewController:(UIViewController *)viewController;
- (void)performScan:(BOOL)start;

- (void)connectToDevice:(GCKDevice*)device;
- (void)disconnectFromDevice;

- (BOOL)loadMedia:(GCKMediaInformation *)media startTime:(NSTimeInterval)startTime autoPlay:(BOOL)autoPlay;
- (void)manageViewController:(UIViewController *)controller icon:(BOOL)icon toolbar:(BOOL)toolbar;

- (BOOL)isConnected;
- (BOOL)isPlayingMedia;
- (BOOL)isPaused;

- (void)updateStatsFromDevice;
- (void)updateActiveTracks;

- (void)pauseCastMedia:(BOOL)shouldPause;
- (void)setPlaybackPercent:(float)newPercent;
- (void)stopCastMedia;
- (void)clearPreviousSession;
- (NSTimeInterval)streamPositionForPreviouslyCastMedia:(NSString *)contentID;

- (void)enableLogging;

- (UIViewController *)castViewControllerForMedia:(GCKMediaInformation *)media withStartingTime:(NSTimeInterval)startTime;
- (void)displayCurrentlyPlayingMedia;

@end