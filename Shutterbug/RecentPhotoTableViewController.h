//
//  RecentPhotoTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "RotatableViewController.h"

@interface RecentPhotoTableViewController : RotatableViewController
@property (nonatomic, strong) NSArray *photos;  // of Flickr photo dictionaries
@end
