//
//  CastIconButton.m
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import "CastIconButton.h"

static const int kCastIconButtonAnimationDuration = 2;

@interface CastIconButton ()

@property (nonatomic) UIImage* castOff;
@property (nonatomic) UIImage* castOn;
@property (nonatomic) NSArray* castConnecting;

@end

@implementation CastIconButton


+ (CastIconButton *)buttonWithFrame:(CGRect)frame {
  return [[CastIconButton alloc] initWithFrame:frame ];
}

- (instancetype)initWithFrame:(CGRect)frame{
  self = [super initWithFrame:frame];
  if (self) {
    self.castOff = [[UIImage imageNamed:@"cast_off"]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.castOn = [[UIImage imageNamed:@"cast_on"]
                   imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.castConnecting = @[
                              [[UIImage imageNamed:@"cast_on0"]
                                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                              [[UIImage imageNamed:@"cast_on1"]
                                 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                              [[UIImage imageNamed:@"cast_on2"]
                                 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate],
                              [[UIImage imageNamed:@"cast_on1"]
                                 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.imageView.animationImages = self.castConnecting;
    self.imageView.animationDuration = kCastIconButtonAnimationDuration;
    self.status = CIBCastUnavailable;
  }
  return self;
}

- (void)setStatus:(CastIconButtonState)status {
  _status = status;
  switch(status) {
    case CIBCastUnavailable:
      [self.imageView stopAnimating];
      [self setHidden:YES];
      break;
    case CIBCastAvailable:
      [self setHidden:NO];
      [self.imageView stopAnimating];
      [self setImage:self.castOff forState:UIControlStateNormal];
      [self setTintColor:self.superview.tintColor];
      break;
    case CIBCastConnecting:
      [self setHidden:NO];
      [self.imageView startAnimating];
      [self setTintColor:self.superview.tintColor];
      break;
    case CIBCastConnected:
      [self setHidden:NO];
      [self.imageView stopAnimating];
      [self setImage:self.castOn forState:UIControlStateNormal];
      [self setTintColor:[UIColor yellowColor]];
      break;
  }
}

@end

@interface CastIconBarButtonItem ()

@end

@implementation CastIconBarButtonItem

+ (CastIconBarButtonItem *)barButtonItemWithTarget:(id)target
                                    selector:(SEL)selector {
  CastIconButton *button = [CastIconButton buttonWithFrame:CGRectMake(0, 0, 29, 22)];
  [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
  CastIconBarButtonItem *barButton = [[self alloc] initWithCustomView:button];
  barButton.button = button;
  return barButton;
}

- (void)setStatus:(CastIconButtonState)status {
  self.button.status = status;
}

- (CastIconButtonState)status {
  return self.button.status;
}

@end
