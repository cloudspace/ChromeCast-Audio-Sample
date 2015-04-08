//
//  CastIconButton.m
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, CastIconButtonState){
  
  CIBCastUnavailable,
  CIBCastAvailable,
  CIBCastConnecting,
  CIBCastConnected
};


@interface CastIconButton : UIButton

@property (nonatomic) CastIconButtonState status;

+ (CastIconButton *)buttonWithFrame:(CGRect)frame;

@end


@interface CastIconBarButtonItem : UIBarButtonItem

@property (nonatomic) CastIconButtonState status;
@property (nonatomic) CastIconButton *button;

+ (CastIconBarButtonItem *)barButtonItemWithTarget:(id)target selector:(SEL)selector;

@end
