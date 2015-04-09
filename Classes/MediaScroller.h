//
//  MediaScroller.h
//  Cast Audio
//
//  Created by Isaac Paul on 4/8/15.
//  Copyright (c) 2015 Google inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media;
@class MediaListModel;

@interface MediaScroller : UIScrollView

- (void)loadMediaList:(MediaListModel*)mediaList withSelectedMedia:(Media*)selectedMedia;

@property (nonatomic, copy) void (^didScrollToMediaBlock) (Media* selectedMedia);

@end
