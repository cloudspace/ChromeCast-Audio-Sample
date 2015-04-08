//
//  GCKMediaInformation+LocalMedia.m
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import "ChromecastDeviceController.h"
#import "GCKMediaInformation+LocalMedia.h"
#import <GoogleCast/GCKMediaMetadata.h>
#import <GoogleCast/GCKMediaTrack.h>
#import "MediaTrack.h"

@implementation GCKMediaInformation (LocalMedia)

+ (GCKMediaInformation *)mediaInformationFromLocalMedia:(Media *)media {
  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeGeneric];
  if (media.title) {
    [metadata setString:media.title forKey:kGCKMetadataKeyTitle];
  }

  if (media.subtitle) {
    [metadata setString:media.subtitle forKey:kGCKMetadataKeySubtitle];
  }

  if (media.thumbnailURL) {
    [metadata addImage:[[GCKImage alloc] initWithURL:media.thumbnailURL width:200 height:100]];
  }

  if (media.posterURL) {
    [metadata setString:[media.posterURL absoluteString] forKey:kCastComponentPosterURL];
  }

  GCKMediaInformation *mi = [[GCKMediaInformation alloc] initWithContentID:[media.URL absoluteString] streamType:GCKMediaStreamTypeNone contentType:media.mimeType metadata:metadata streamDuration:0 mediaTracks:nil textTrackStyle:[ChromecastDeviceController sharedInstance].textTrackStyle customData:nil];
  return mi;
}

+ (GCKMediaTrackType)trackTypeFrom:(NSString *)string {
  if ([string isEqualToString:@"audio"])
    return GCKMediaTrackTypeAudio;

  if ([string isEqualToString:@"text"])
    return GCKMediaTrackTypeText;

  if ([string isEqualToString:@"video"])
    return GCKMediaTrackTypeVideo;

  return GCKMediaTrackTypeUnknown;
}

+ (GCKMediaTextTrackSubtype)trackSubtypeFrom:(NSString *)string {
  if ([string isEqualToString:@"captions"])
    return GCKMediaTextTrackSubtypeCaptions;

  if ([string isEqualToString:@"chapters"])
    return GCKMediaTextTrackSubtypeChapters;

  if ([string isEqualToString:@"descriptions"])
    return GCKMediaTextTrackSubtypeDescriptions;

  if ([string isEqualToString:@"metadata"])
    return GCKMediaTextTrackSubtypeMetadata;

  if ([string isEqualToString:@"subtitles"])
    return GCKMediaTextTrackSubtypeSubtitles;

  return GCKMediaTextTrackSubtypeUnknown;
}

@end
