//
//  CastViewController.m
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import "AppDelegate.h"
#import "CastViewController.h"
#import "SimpleImageFetcher.h"

@interface CastViewController () {
  NSTimeInterval _mediaStartTime;
  BOOL _currentlyDraggingSlider;
  BOOL _readyToShowInterface;
  BOOL _joinExistingSession;
  NSTimeInterval _lastKnownTime;
  __weak ChromecastDeviceController* _chromecastController;
}

@property IBOutlet UIImageView* thumbnailImage;
@property IBOutlet UILabel* castingToLabel;
@property (weak, nonatomic) IBOutlet UILabel* mediaTitleLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* castActivityIndicator;

@property (weak, nonatomic) NSTimer* updateStreamTimer;
@property (weak, nonatomic) NSTimer* fadeVolumeControlTimer;

@property (nonatomic) UILabel* currTime;
@property (nonatomic) UILabel* totalTime;
@property (nonatomic) UIButton* volumeButton;
@property (nonatomic) UIButton* playButton;
@property (nonatomic) UISlider* slider;

@property (nonatomic) UIView *toolbarView;
@property (nonatomic) NSDictionary *viewsDictionary;

@property (nonatomic) UIImage *playImage;
@property (nonatomic) UIImage *pauseImage;

@property BOOL isManualVolumeChange;
@property BOOL visible;

@end

@implementation CastViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.visible = false;

  _chromecastController = [ChromecastDeviceController sharedInstance];

  self.castingToLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Casting to %@", nil),
      _chromecastController.deviceName];
  self.mediaTitleLabel.text = [self.mediaToPlay.metadata stringForKey:kGCKMetadataKeyTitle];

  self.volumeControlLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Volume", nil),_chromecastController.deviceName];
  self.volumeSlider.minimumValue = 0;
  self.volumeSlider.maximumValue = 1.0;
  self.volumeSlider.value = _chromecastController.deviceVolume ?
      _chromecastController.deviceVolume : 0.5;
  self.volumeSlider.continuous = NO;
  [self.volumeSlider addTarget:self
                        action:@selector(sliderValueChanged:)
              forControlEvents:UIControlEventValueChanged];

  _isManualVolumeChange = NO;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(receivedVolumeChangedNotification:)
                                               name:@"Volume changed"
                                             object:_chromecastController];

  UIButton *transparencyButton = [[UIButton alloc] initWithFrame:self.view.bounds];
  transparencyButton.autoresizingMask =
      (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  transparencyButton.backgroundColor = [UIColor clearColor];
  [self.view insertSubview:transparencyButton aboveSubview:self.thumbnailImage];
  [transparencyButton addTarget:self
                         action:@selector(showVolumeSlider:)
               forControlEvents:UIControlEventTouchUpInside];
  [self initControls];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  // Assign ourselves as delegate ONLY in viewWillAppear of a view controller.
  _chromecastController.delegate = self;

  [[ChromecastDeviceController sharedInstance] manageViewController:self icon:YES toolbar:NO];

  // Make the navigation bar transparent.
  self.navigationController.navigationBar.translucent = YES;
  [self.navigationController.navigationBar setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.40f]];
  [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
  self.navigationController.navigationBar.shadowImage = [UIImage new];

  self.toolbarView.hidden = YES;
  [self.playButton setImage:self.playImage forState:UIControlStateNormal];

  [self resetInterfaceElements];

  if (_joinExistingSession == YES) {
    [self mediaNowPlaying];
  }

  [self configureView];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.visible = true;
  if (!_chromecastController.isConnected) {
    // If we're not connected, exit.
    [self maybePopController];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  // I think we can safely stop the timer here
  [self.updateStreamTimer invalidate];
  self.updateStreamTimer = nil;

  // We no longer want to be delegate.
  _chromecastController.delegate = nil;

  [self.navigationController.navigationBar setBackgroundImage:nil
                                                forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidDisappear:(BOOL)animated {
  self.visible = false;
  [super viewDidDisappear:animated];
}

- (void)receivedVolumeChangedNotification:(NSNotification *) notification {
    if(!_isManualVolumeChange) {
      ChromecastDeviceController *deviceController = (ChromecastDeviceController *) notification.object;
      NSLog(@"Got volume changed notification: %g", deviceController.deviceVolume);
      self.volumeSlider.value = _chromecastController.deviceVolume;
    }
}

- (IBAction)sliderValueChanged:(id)sender {
    UISlider *slider = (UISlider *) sender;
    // Essentially a fake lock to prevent us from being stuck in an endless loop (volume change
    // triggers notification, triggers UI change, triggers volume change ...
    // This method is not foolproof (not thread safe), but for most use cases *should* be safe
    // enough.
    _isManualVolumeChange = YES;
    NSLog(@"Got new slider value: %.2f", slider.value);
    _chromecastController.deviceVolume = slider.value;
    _isManualVolumeChange = NO;
}

- (IBAction)unwindToCastView:(UIStoryboardSegue *)segue; {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)maybePopController {
  // Only take action if we're visible.
  if (self.visible) {
    self.mediaToPlay = nil; // Forget media.
    [self.navigationController popViewControllerAnimated:YES];
  }
}

#pragma mark - Managing the detail item

- (void)setMediaToPlay:(GCKMediaInformation *)newDetailItem {
  [self setMediaToPlay:newDetailItem withStartingTime:0];
}

- (void)setMediaToPlay:(GCKMediaInformation *)newMedia withStartingTime:(NSTimeInterval)startTime {
  _mediaStartTime = startTime;
  if (_mediaToPlay != newMedia) {
    _mediaToPlay = newMedia;
  }
}

- (void)resetInterfaceElements {
  self.totalTime.text = @"";
  self.currTime.text = @"";
  [self.slider setValue:0];
  [self.castActivityIndicator startAnimating];
  _currentlyDraggingSlider = NO;
  self.toolbarView.hidden = YES;
  _readyToShowInterface = NO;
}

- (IBAction)showVolumeSlider:(id)sender {
  if(self.volumeControls.hidden) {
    self.volumeControls.hidden = NO;
    [self.volumeControls setAlpha:0];

    [UIView animateWithDuration:0.5
                     animations:^{
                       self.volumeControls.alpha = 1.0;
                     }
                     completion:^(BOOL finished){
                       NSLog(@"Done!");
                     }];

  }
  // Do this so if a user taps the screen or plays with the volume slider, it resets the timer
  // for fading the volume controls
  if(self.fadeVolumeControlTimer != nil) {
    [self.fadeVolumeControlTimer invalidate];
  }
  self.fadeVolumeControlTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                 target:self
                                                               selector:@selector(fadeVolumeSlider:)
                                                               userInfo:nil repeats:NO];
}

- (void)fadeVolumeSlider:(NSTimer *)timer {
  [self.volumeControls setAlpha:1.0];

  [UIView animateWithDuration:0.5
                   animations:^{
                     self.volumeControls.alpha = 0.0;
                   }
                   completion:^(BOOL finished){
                     self.volumeControls.hidden = YES;
                   }];
}


- (void)mediaNowPlaying {
  _readyToShowInterface = YES;
  [self updateInterfaceFromCast:nil];
  self.toolbarView.hidden = NO;
}

- (void)updateInterfaceFromCast:(NSTimer*)timer {
  [_chromecastController updateStatsFromDevice];

  if (!_readyToShowInterface)
    return;

  if (_chromecastController.playerState != GCKMediaPlayerStateBuffering) {
    [self.castActivityIndicator stopAnimating];
  } else {
    [self.castActivityIndicator startAnimating];
  }

  if (_chromecastController.streamDuration > 0 && !_currentlyDraggingSlider) {
    _lastKnownTime = _chromecastController.streamPosition;
    self.currTime.text = [self getFormattedTime:_chromecastController.streamPosition];
    self.totalTime.text = [self getFormattedTime:_chromecastController.streamDuration];
    [self.slider
        setValue:(_chromecastController.streamPosition / _chromecastController.streamDuration)
        animated:YES];
  }
  [self updateToolbarControls];
}


- (void)updateToolbarControls {
  if (_chromecastController.playerState == GCKMediaPlayerStatePaused ||
      _chromecastController.playerState == GCKMediaPlayerStateIdle) {
    [self.playButton setImage:self.playImage forState:UIControlStateNormal];
  } else if (_chromecastController.playerState == GCKMediaPlayerStatePlaying ||
             _chromecastController.playerState == GCKMediaPlayerStateBuffering) {
    [self.playButton setImage:self.pauseImage forState:UIControlStateNormal];
  }
}

// Little formatting option here
- (NSString*)getFormattedTime:(NSTimeInterval)timeInSeconds {
  int seconds = round(timeInSeconds);
  int hours = seconds / (60 * 60);
  seconds %= (60 * 60);

  int minutes = seconds / 60;
  seconds %= 60;

  if (hours > 0) {
    return [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
  } else {
    return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
  }
}

- (void)configureView {
  if (self.mediaToPlay && _chromecastController.isConnected) {
    NSURL* url = self.mediaToPlay.customData;
    NSString *title = [_mediaToPlay.metadata stringForKey:kGCKMetadataKeyTitle];
    self.castingToLabel.text =
        [NSString stringWithFormat:@"Casting to %@", _chromecastController.deviceName];
    self.mediaTitleLabel.text = title;

    NSLog(@"Casting movie %@ at starting time %f", url, _mediaStartTime);

    //Loading thumbnail async
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSString *posterURL = [_mediaToPlay.metadata stringForKey:kCastComponentPosterURL];
      if (posterURL) {
        UIImage* image = [UIImage
            imageWithData:[SimpleImageFetcher getDataFromImageURL:[NSURL URLWithString:posterURL]]];

        dispatch_async(dispatch_get_main_queue(), ^{
          NSLog(@"Loaded thumbnail image");
          self.thumbnailImage.image = image;
          [self.view setNeedsLayout];
        });
      }
    });

    NSString *cur = [_chromecastController.mediaInformation.metadata
                        stringForKey:kGCKMetadataKeyTitle];
    // If the newMedia is already playing, join the existing session.
    if (![title isEqualToString:cur] ||
          _chromecastController.playerState == GCKMediaPlayerStateIdle) {
      //Cast the movie!
      [_chromecastController loadMedia:self.mediaToPlay
                             startTime:_mediaStartTime
                              autoPlay:YES];
      _joinExistingSession = NO;
    } else {
      _joinExistingSession = YES;
      [self mediaNowPlaying];
    }

    // Start the timer
    if (self.updateStreamTimer) {
      [self.updateStreamTimer invalidate];
      self.updateStreamTimer = nil;
    }

    self.updateStreamTimer =
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(updateInterfaceFromCast:)
                                       userInfo:nil
                                        repeats:YES];

  }
}

#pragma mark - On - screen UI elements
- (IBAction)playButtonClicked:(id)sender {
  if ([_chromecastController isPaused]) {
    [_chromecastController pauseCastMedia:NO];
  } else {
    [_chromecastController pauseCastMedia:YES];
  }
}

- (IBAction)onTouchDown:(id)sender {
  _currentlyDraggingSlider = YES;
}

// This is continuous, so we can update the current/end time labels
- (IBAction)onSliderValueChanged:(id)sender {
  float pctThrough = [self.slider value];
  if (_chromecastController.streamDuration > 0) {
    self.currTime.text =
        [self getFormattedTime:(pctThrough * _chromecastController.streamDuration)];
  }
}
// This is called only on one of the two touch up events
- (void)touchIsFinished {
  [_chromecastController setPlaybackPercent:[self.slider value]];
  _currentlyDraggingSlider = NO;
}

- (IBAction)onTouchUpInside:(id)sender {
  NSLog(@"Touch up inside");
  [self touchIsFinished];

}
- (IBAction)onTouchUpOutside:(id)sender {
  NSLog(@"Touch up outside");
  [self touchIsFinished];
}

#pragma mark - ChromecastControllerDelegate

/**
 * Called when connection to the device was closed.
 */
- (void)didDisconnect {
  [self maybePopController];
}

/**
 * Called when the playback state of media on the device changes.
 */
- (void)didReceiveMediaStateChange {
  NSString *currentlyPlayingMediaTitle = [_chromecastController.mediaInformation.metadata
                                          stringForKey:kGCKMetadataKeyTitle];
  NSString *title = [_mediaToPlay.metadata stringForKey:kGCKMetadataKeyTitle];

  if (currentlyPlayingMediaTitle &&
      ![title isEqualToString:currentlyPlayingMediaTitle]) {
    // The state change is related to old media, so ignore it.
    NSLog(@"Got message for media %@ while on %@", currentlyPlayingMediaTitle, title);
    return;
  }

  if (_chromecastController.playerState == GCKMediaPlayerStateIdle && _mediaToPlay) {
    [self maybePopController];
    return;
  }

  _readyToShowInterface = YES;
  if ([self isViewLoaded] && self.view.window) {
    // Display toolbar if we are current view.
    self.toolbarView.hidden = NO;
  }
}

#pragma mark - implementation.
- (void)initControls {

  // Play/Pause images.
  self.playImage = [UIImage imageNamed:@"media_play"];
  self.pauseImage = [UIImage imageNamed:@"media_pause"];

  // Toolbar.
  self.toolbarView = [[UIView alloc] initWithFrame:self.navigationController.toolbar.frame];
  self.toolbarView.translatesAutoresizingMaskIntoConstraints = NO;
  // Hide the nav controller toolbar - we are managing our own to get autolayout.
  self.navigationController.toolbarHidden = YES;

  // Play/Pause button.
  self.playButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.playButton setFrame:CGRectMake(0, 0, 40, 40)];
  if ([_chromecastController isPaused]) {
    [self.playButton setImage:self.playImage forState:UIControlStateNormal];
  } else {
    [self.playButton setImage:self.pauseImage forState:UIControlStateNormal];
  }
  [self.playButton addTarget:self
                      action:@selector(playButtonClicked:)
            forControlEvents:UIControlEventTouchUpInside];
  self.playButton.tintColor = [UIColor whiteColor];
  NSLayoutConstraint *constraint =[NSLayoutConstraint
                                   constraintWithItem:self.playButton
                                   attribute:NSLayoutAttributeHeight
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.playButton
                                   attribute:NSLayoutAttributeWidth
                                   multiplier:1.0
                                   constant:0.0f];
  [self.playButton addConstraint:constraint];
  self.playButton.translatesAutoresizingMaskIntoConstraints = NO;

  // Current time.
  self.currTime = [[UILabel alloc] init];
  self.currTime.clearsContextBeforeDrawing = YES;
  self.currTime.text = @"00:00";
  [self.currTime setFont:[UIFont fontWithName:@"Helvetica" size:14.0]];
  [self.currTime setTextColor:[UIColor whiteColor]];
  self.currTime.tintColor = [UIColor whiteColor];
  self.currTime.translatesAutoresizingMaskIntoConstraints = NO;

  // Total time.
  self.totalTime = [[UILabel alloc] init];
  self.totalTime.clearsContextBeforeDrawing = YES;
  self.totalTime.text = @"00:00";
  [self.totalTime setFont:[UIFont fontWithName:@"Helvetica" size:14.0]];
  [self.totalTime setTextColor:[UIColor whiteColor]];
  self.totalTime.tintColor = [UIColor whiteColor];
  self.totalTime.translatesAutoresizingMaskIntoConstraints = NO;

  // Volume control.
  self.volumeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.volumeButton setFrame:CGRectMake(0, 0, 40, 40)];
  [self.volumeButton setImage:[UIImage imageNamed:@"icon_volume3"] forState:UIControlStateNormal];
  [self.volumeButton addTarget:self
                      action:@selector(showVolumeSlider:)
            forControlEvents:UIControlEventTouchUpInside];
  self.volumeButton.tintColor = [UIColor whiteColor];
  constraint =[NSLayoutConstraint
                                   constraintWithItem:self.volumeButton
                                   attribute:NSLayoutAttributeHeight
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.volumeButton
                                   attribute:NSLayoutAttributeWidth
                                   multiplier:1.0
                                   constant:0.0f];
  [self.volumeButton addConstraint:constraint];
  self.volumeButton.translatesAutoresizingMaskIntoConstraints = NO;

  // Slider.
  self.slider = [[UISlider alloc] init];
  UIImage *thumb = [UIImage imageNamed:@"thumb.png"];
  [self.slider setThumbImage:thumb forState:UIControlStateNormal];
  [self.slider setThumbImage:thumb forState:UIControlStateHighlighted];
  [self.slider addTarget:self
                  action:@selector(onSliderValueChanged:)
        forControlEvents:UIControlEventValueChanged];
  [self.slider addTarget:self
                  action:@selector(onTouchDown:)
        forControlEvents:UIControlEventTouchDown];
  [self.slider addTarget:self
                  action:@selector(onTouchUpInside:)
        forControlEvents:UIControlEventTouchUpInside];
  [self.slider addTarget:self
                  action:@selector(onTouchUpOutside:)
        forControlEvents:UIControlEventTouchCancel];
  [self.slider addTarget:self
                  action:@selector(onTouchUpOutside:)
        forControlEvents:UIControlEventTouchUpOutside];
  self.slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.slider.minimumValue = 0;
  self.slider.minimumTrackTintColor = [UIColor yellowColor];
  self.slider.translatesAutoresizingMaskIntoConstraints = NO;

  [self.view addSubview:self.toolbarView];
  [self.toolbarView addSubview:self.playButton];
  [self.toolbarView addSubview:self.volumeButton];
  [self.toolbarView addSubview:self.currTime];
  [self.toolbarView addSubview:self.slider];
  [self.toolbarView addSubview:self.totalTime];

  // Round the corners on the volume pop up.
  self.volumeControls.layer.cornerRadius = 5;
  self.volumeControls.layer.masksToBounds = YES;

  // Layout.
  NSString *hlayout =
  @"|-(<=5)-[playButton(==35)]-[volumeButton(==30)]-[currTime]-[slider(>=90)]-[totalTime]-(<=5)-|";
  self.viewsDictionary = @{ @"slider" : self.slider,
                            @"currTime" : self.currTime,
                            @"totalTime" :  self.totalTime,
                            @"playButton" : self.playButton,
                            @"volumeButton" : self.volumeButton
                            };
  [self.toolbarView addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:hlayout
                                           options:NSLayoutFormatAlignAllCenterY
                                           metrics:nil views:self.viewsDictionary]];

   NSString *vlayout = @"V:[slider(==35)]-|";
  [self.toolbarView addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:vlayout
                                           options:0
                                           metrics:nil views:self.viewsDictionary]];

  // Autolayout toolbar.
  NSString *toolbarVLayout = @"V:[toolbar(==44)]|";
  NSString *toolbarHLayout = @"|[toolbar]|";
  [self.view addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:toolbarVLayout
                                           options:0
                                           metrics:nil views:@{@"toolbar" : self.toolbarView}]];
  [self.view addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:toolbarHLayout
                                           options:0
                                           metrics:nil views:@{@"toolbar" : self.toolbarView}]];
}
@end