//
//  RecentPhotoTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "RecentFlickrPhotoViewController.h"
#import "FlickrFetcher.h"

@implementation RecentFlickrPhotoViewController

// Load in the defaults from the 
- (void)loadDefaults
{
    NSArray *defaultRecents = [[NSUserDefaults standardUserDefaults] objectForKey:RECENTS_KEY];
    if (defaultRecents) {
        [self setPhotos:defaultRecents];
    }
}

// Have to do on viewDidAppear so as we reload the recents list when using the
// TabBarController. Otherwise we don't get the latest added picture when we switch back
// and forth. Does this have to do with weak/strong? How does the UITableViewController for the other
// TabBar View Controller stay in memory?
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadDefaults];
}


#define SORT_RECENTS_ON_VIEW @"sort_recents_on_view"
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Call the inherited...
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    // Unique to this class
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SORT_RECENTS_ON_VIEW]) [self addToRecents];
}
@end
