//
//  MediaListModel.m
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import "MediaListModel.h"

@interface MediaListModel ()

@property (strong, nonatomic) NSArray* mediaFiles;

@end

@implementation MediaListModel

- (void)loadMedia:(void (^)(void))callbackBlock {
  
  Media *media3Birds = [self defaultMedia:@"https://dl.dropboxusercontent.com/u/55180996/Music/threelittlebirds.mp3" artist:@"Bob Marley" thumbnail:@"http://www.spacecoast-cdr.com/Miscellaneous/bm-1979-12-02-whole-front.jpg"];
  Media *mediaSymphony = [self defaultMedia:@"https://dl.dropboxusercontent.com/u/55180996/Music/SymphonyNo.5.mp3" artist:@"Ludwig Van Beethoven" thumbnail:@"http://upload.wikimedia.org/wikipedia/commons/6/6f/Beethoven.jpg"];
  Media *mediaHappy = [self defaultMedia:@"https://dl.dropboxusercontent.com/u/55180996/Music/Pharrell%20-%20Happy.mp3" artist:@"Pharrell Williams" thumbnail:@"http://upload.wikimedia.org/wikipedia/en/2/23/Pharrell_Williams_-_Happy.jpg"];
  Media *mediaLOVE = [self defaultMedia:@"https://dl.dropboxusercontent.com/u/55180996/Music/Nat%20King%20Cole%20-%20L%20O%20V%20E.mp3" artist:@"Nat King Cole" thumbnail:@"http://upload.wikimedia.org/wikipedia/commons/8/83/Nat_King_Cole_(Gottlieb_01511).jpg"];
  
  self.mediaFiles = @[media3Birds, mediaSymphony, mediaHappy, mediaLOVE];
  if (callbackBlock)
    callbackBlock();
}

- (NSString*) decodeFromPercentEscapeString:(NSString *) string {
  return (__bridge NSString *) CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef) string, CFSTR(""), kCFStringEncodingUTF8);
}

- (Media*)defaultMedia:(NSString*)url artist:(NSString*)artist thumbnail:(NSString*)thumb {
  Media *media = [Media new];
  media.title = [self decodeFromPercentEscapeString:[url lastPathComponent]];
  media.descrip = @"No Description";
  media.mimeType = @"audio/mpeg";
  media.subtitle = artist;
  media.URL = [NSURL URLWithString:url];
  media.thumbnailURL = [NSURL URLWithString:thumb];
  media.posterURL = media.thumbnailURL;
  return media;
}

- (int)numberOfMediaLoaded {
  return (int)[_mediaFiles count];
}

- (Media *)mediaAtIndex:(int)index {
  if (index < 0 || index >= _mediaFiles.count)
  {
    NSLog(@"ERROR: Out of bounds!");
    return nil;
  }
  return (Media *)[_mediaFiles objectAtIndex:index];
}

- (int)indexOfMediaByTitle:(NSString *)title {
  for (int i = 0; i < self.numberOfMediaLoaded; i++) {
    Media *media = [self mediaAtIndex:i];
    if ([media.title isEqualToString:title]) {
      return i;
    }
  }
  return -1;
}

@end