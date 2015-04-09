//
//  CastViewController.h
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import "ChromecastDeviceController.h"
#import <UIKit/UIKit.h>

@interface CastViewController : UIViewController<ChromecastControllerDelegate>

@property (strong, nonatomic, readonly) GCKMediaInformation* mediaToPlay;

@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;
@property (strong, nonatomic) IBOutlet UIView *volumeControls;
@property (weak,   nonatomic) IBOutlet UILabel *volumeControlLabel;

- (void)setMediaToPlay:(GCKMediaInformation *)newMedia withStartingTime:(NSTimeInterval)startTime selectedMedia:(Media*)media mediaList:(MediaListModel*)mediaList;

- (IBAction)showVolumeSlider:(id)sender;

@end