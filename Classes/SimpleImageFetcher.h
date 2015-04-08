//
//  SimpleImageFetcher.h
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SimpleImageFetcher : NSObject

+ (NSData *)getDataFromImageURL:(NSURL *)urlToFetch;
+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)newSize;

@end