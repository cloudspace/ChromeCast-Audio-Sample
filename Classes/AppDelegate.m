
#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "ChromecastDeviceController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

  //[[ChromecastDeviceController sharedInstance] enableLogging];
  [ChromecastDeviceController sharedInstance].applicationID = kGCKMediaDefaultReceiverApplicationID;

  // Set playback category mode to allow playing audio even when the ringer
  // mute switch is on.
  [self setPlaybackCategory:AVAudioSessionCategoryPlayback];
  
  UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  // Fetch viewcontroller from the storyboard ID that you have set in Interface Builder
  UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"RootNavController"];
  [vc setModalPresentationStyle:UIModalPresentationFullScreen];
  [_window.rootViewController addChildViewController:vc];
  [_window.rootViewController.view addSubview:vc.view];
  // Put in the disired size and position.
  vc.view.frame = CGRectMake(0.0f, 20.0f, vc.view.frame.size.width, vc.view.frame.size.height - 20.0f);

  return YES;
}

- (void)setPlaybackCategory:(NSString*)category {
  NSError *error;
  BOOL success = [[AVAudioSession sharedInstance] setCategory:category error:&error];
  if (!success) {
    NSLog(@"Error setting audio category: %@", error.localizedDescription);
  }
}

@end