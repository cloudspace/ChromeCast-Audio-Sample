//
//  MediaScroller.m
//  Cast Audio
//
//  Created by Isaac Paul on 4/8/15.
//  Copyright (c) 2015 Google inc. All rights reserved.
//

#import "MediaScroller.h"
#import "MediaListModel.h"
#import "SimpleImageFetcher.h"

@interface MediaScroller () <UIScrollViewDelegate>

@property (assign, nonatomic) NSUInteger currentPage;
@property (strong, nonatomic) MediaListModel* mediaList;
@property (strong, nonatomic) NSArray* images;

@end

@implementation MediaScroller

- (void)awakeFromNib {
  [super awakeFromNib];
  self.delegate = self;
  _images = @[];
  _currentPage = 0;
  self.pagingEnabled = true;
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

- (void)setFrame:(CGRect)frame {
  [super setFrame:frame];
  
  CGRect imageFrame = self.bounds;
  for (int i = 0; i < [self.images count]; i+= 1) {
    UIImageView* eachView = self.images[i];
    imageFrame.origin.x = i * imageFrame.size.width;
    eachView.frame = imageFrame;
  }
}
- (void)layoutSubviews {
  [super layoutSubviews];
  CGRect imageFrame = self.bounds;
  for (int i = 0; i < [self.images count]; i+= 1) {
    UIImageView* eachView = self.images[i];
    imageFrame.origin.x = i * imageFrame.size.width;
    eachView.frame = imageFrame;
  }
  self.contentSize = CGSizeMake(imageFrame.size.width * self.images.count, imageFrame.size.height);
  //[self gotoPage:_currentPage];
}

- (void)gotoPage:(NSUInteger)page {
  [self setContentOffset:CGPointMake(page * self.frame.size.width, self.contentOffset.y)];
  if (page == _currentPage)
    return;
  _currentPage = page;
  [self didScrollToNewMedia];
}

- (void)loadMediaList:(MediaListModel*)mediaList withSelectedMedia:(Media*)selectedMedia {
  _mediaList = mediaList;
  
  [self removeAllImages];
  
  CGRect imageFrame = self.bounds;
  
  self.images = [mediaList toUIImageViews];
  for (int i = 0; i < [self.images count]; i+= 1) {
    UIImageView* eachView = self.images[i];
    imageFrame.origin.x = i * imageFrame.size.width;
    eachView.frame = imageFrame;
    [self addSubview:eachView];
  }
  
  self.contentOffset = CGPointZero;
  self.contentSize = CGSizeMake(imageFrame.size.width * self.images.count, imageFrame.size.height);
  
  NSUInteger pageForSelectedMedia = [self.mediaList.mediaFiles indexOfObject:selectedMedia];
  [self gotoPage:pageForSelectedMedia];
}

- (void)removeAllImages {
  for (UIImageView* eachImage in _images)
  {
    [eachImage removeFromSuperview];
  }
  self.images = @[];
}

- (void)didScrollToNewMedia {
  Media* selectedMedia = [_mediaList mediaAtIndex:(int)_currentPage];
  
  if (self.didScrollToMediaBlock)
    self.didScrollToMediaBlock(selectedMedia);
  
}

@end
