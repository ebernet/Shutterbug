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

// Lod the photos from the recents stored in NSUserDefaults. No threading necessary (FAST)
// TabBar View Controller stay in memory?
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadDefaults];
}
@end