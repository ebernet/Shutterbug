//
//  RecentPhotoTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "RotatableViewController.h"
#import "DetailViewController.h"

// To store/retrieve the recents
#define RECENTS_KEY @"DetailViewController.Recents"

@interface PhotoTableViewController : RotatableViewController

// Made this public so as I could do an addToRecents when doing a showPhoto when showing 1st time
- (void)showPhoto;

@property (nonatomic, strong) NSArray *photos;  // of Flickr photo dictionaries
@property (nonatomic, strong) NSDictionary *photoToDisplay;

// We want all our decendents to have visible spinners
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end
