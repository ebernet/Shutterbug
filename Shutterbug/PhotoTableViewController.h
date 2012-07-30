//
//  RecentPhotoTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "RotatableViewController.h"
#import "DetailViewController.h"

@interface PhotoTableViewController : RotatableViewController
@property (nonatomic, strong) NSArray *photos;  // of Flickr photo dictionaries


// We want all our decendents to have visible spinners
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end
