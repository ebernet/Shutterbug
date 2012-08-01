//
//  RecentPhotoTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "RecentPhotoTableViewController.h"
#import "FlickrFetcher.h"

@interface RecentPhotoTableViewController ()
@property (nonatomic, strong) NSDictionary *photoToDisplay;
@end

@implementation RecentPhotoTableViewController
@synthesize photoToDisplay = _photoToDisplay;


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

@end
