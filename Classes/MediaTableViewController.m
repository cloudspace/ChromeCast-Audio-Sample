//
//  MediaTableViewController.m
//  na
//
//  Created by Isaac Paul on 4/7/14.
//  Copyright (c) 2014 CSORGNAME. All rights reserved.
//

#import "AppDelegate.h"
#import "ChromecastDeviceController.h"
#import "Media.h"
#import "MediaListModel.h"
#import "MediaTableViewController.h"
#import "SimpleImageFetcher.h"
#import "GCKMediaInformation+LocalMedia.h"
#import "CastIconButton.h"

@interface MediaTableViewController () <ChromecastControllerDelegate>

@property (nonatomic, strong) MediaListModel *mediaList;

@end

@implementation MediaTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Show stylized application title in the titleview.
  self.navigationItem.title = @"Cast Music";

  // Asynchronously load the media json.
  AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
  delegate.mediaList = [[MediaListModel alloc] init];
  self.mediaList = delegate.mediaList;
  [self.mediaList loadMedia:^{
    self.title = self.mediaList.mediaTitle;
    [self.tableView reloadData];
  }];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  // Assign ourselves as delegate ONLY in viewWillAppear of a view controller.
  [ChromecastDeviceController sharedInstance].delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.navigationController.navigationBar.topItem.title = @"Cast Music";
  [[ChromecastDeviceController sharedInstance] manageViewController:self icon:YES toolbar:YES];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.mediaList numberOfMediaLoaded];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
  Media *media = [self.mediaList mediaAtIndex:(int)indexPath.row];

  UILabel *mediaTitle = (UILabel *)[cell viewWithTag:1];
  mediaTitle.text = media.title;

  UILabel *mediaOwner = (UILabel *)[cell viewWithTag:2];
  mediaOwner.text = media.subtitle;

  // Asynchronously load the table view image
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

  dispatch_async(queue, ^{
    UIImage *image =
        [UIImage imageWithData:[SimpleImageFetcher getDataFromImageURL:media.thumbnailURL]];

    dispatch_sync(dispatch_get_main_queue(), ^{
      UIImageView *mediaThumb = (UIImageView *)[cell viewWithTag:3];
      [mediaThumb setImage:image];
      [cell setNeedsLayout];
    });
  });

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  ChromecastDeviceController *controller = [ChromecastDeviceController sharedInstance];
  if (controller.isConnected == false) {
    
    CastIconBarButtonItem* chromeCastButton = (CastIconBarButtonItem*)self.navigationController.navigationBar.topItem.rightBarButtonItem;
    
    if (chromeCastButton.button.hidden)
    {
      UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Could not find any chrome casts on the current network." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      [alert show];
      return;
    }
    [chromeCastButton.button sendActionsForControlEvents:UIControlEventTouchUpInside];
    return;
  }

  Media* media = [self.mediaList mediaAtIndex:(int)indexPath.row];
  [self castMedia:media from:0];
}

- (void)castMedia:(Media*)mediaToPlay from:(NSTimeInterval)from {
  if (from < 0) {
    from = 0;
  }
  ChromecastDeviceController *controller = [ChromecastDeviceController sharedInstance];
  GCKMediaInformation *media = [GCKMediaInformation mediaInformationFromLocalMedia:mediaToPlay];
  UIViewController *cvc = [controller castViewControllerForMedia:media withStartingTime:from];
  [self.navigationController pushViewController:cvc animated:YES];
}


@end