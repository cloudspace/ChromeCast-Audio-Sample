//
//  Media.h
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Media : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *descrip;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSURL *thumbnailURL;
@property (nonatomic, strong) NSURL *posterURL;

@end