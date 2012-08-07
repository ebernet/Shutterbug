//
//  RecentsFlickrViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "RecentsFlickrViewController.h"
#import "FlickrFetcher.h"

// To store/retrieve the recents
#define RECENTS_KEY @"DetailViewController.Recents"

@implementation RecentsFlickrViewController

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
