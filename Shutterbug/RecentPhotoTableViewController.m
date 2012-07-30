//
//  RecentPhotoTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "RecentPhotoTableViewController.h"
#import "FlickrFetcher.h"
#import "DetailViewController.h"


@implementation RecentPhotoTableViewController
@synthesize photos = _photos;


- (void)loadDefaults
{
    NSArray *defaultRecents = [[NSUserDefaults standardUserDefaults] objectForKey:RECENTS_KEY];
    if (defaultRecents) {
        [self setPhotos:defaultRecents];
    }
}

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        if (self.tableView.window) [self.tableView reloadData];
    }
}

// Have to do on viewDidAppear so as we reload the recents list
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadDefaults];
}

@end
