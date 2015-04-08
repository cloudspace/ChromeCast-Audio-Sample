//
//  CastMiniController.h
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleCast/GCKMediaStatus.h>

@protocol CastMiniControllerDelegate <NSObject>

- (void)displayCurrentlyPlayingMedia;
- (void)pauseCastMedia:(BOOL)pauseOrResume;

@end

@interface CastMiniController : NSObject

- (instancetype)initWithDelegate:(id<CastMiniControllerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (void)updateToolbarStateIn:(UIViewController *)viewController
         forMediaInformation:(GCKMediaInformation *)info
                 playerState:(GCKMediaPlayerState)state;

@end
