//
//  MediaScroller.m
//  Cast Audio
//
//  Created by Isaac Paul on 4/8/15.
//  Copyright (c) 2015 Google inc. All rights reserved.
//

#import "MediaScroller.h"
#import "MediaListModel.h"

@interface MediaScroller () <UIScrollViewDelegate>

@property (assign, nonatomic) int currentPage;
@property (strong, nonatomic) MediaListModel* mediaList;
@property (strong, nonatomic) NSArray* images;

@end

@implementation MediaScroller

- (void)awakeFromNib {
  [super awakeFromNib];
  self.delegate = self;
  _images = @[];
  _currentPage = 0;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  int indexOfPage = scrollView.contentOffset.x / scrollView.frame.size.width;
  if (indexOfPage != _currentPage)
  {
    _currentPage = indexOfPage;
    [self didScrollToNewMedia];
  }
}

- (void)loadMediaList:(MediaListModel*)mediaList {
  _mediaList = mediaList;
}

- (void)didScrollToNewMedia {
  Media* selectedMedia = [_mediaList mediaAtIndex:_currentPage];
  
  if (self.didScrollToMediaBlock)
    self.didScrollToMediaBlock(selectedMedia);
  
}

@end
