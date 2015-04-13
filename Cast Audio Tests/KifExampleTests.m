//
//  KifExampleTests.m
//  Cast Audio
//
//  Created by Isaac Paul on 4/13/15.
//
//

#import "KifExampleTests.h"

@implementation KifExampleTests

- (void)beforeEach
{
}

- (void)afterEach
{
}

- (void)testNotConnected_TapOnMediaInTable
{
  NSIndexPath* index = [NSIndexPath indexPathForRow:0 inSection:0];
  [tester waitForCellAtIndexPath:index inTableViewWithAccessibilityIdentifier:@"Table View - Music"];
  [tester tapRowAtIndexPath:index inTableViewWithAccessibilityIdentifier:@"Table View - Music"];
  
  // The Alert accessibility label is the same as its title
  [tester waitForViewWithAccessibilityLabel:@""];
}

@end
