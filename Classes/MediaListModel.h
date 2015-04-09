//
//  MediaListModel.h
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Media.h"

@interface MediaListModel : NSObject

@property (strong, nonatomic) NSArray* mediaFiles;
@property (nonatomic, strong) NSString* mediaTitle;
@property (nonatomic, readonly) int numberOfMediaLoaded;

- (void)loadMedia:(void (^)(void))callbackBlock;
- (Media *)mediaAtIndex:(int)index;
- (int)indexOfMediaByTitle:(NSString *)title;

- (NSArray*)toUIImageViews;

@end