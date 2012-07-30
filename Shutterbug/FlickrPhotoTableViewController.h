//
//  FlickrPhotoTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoTableViewController.h"

@interface FlickrPhotoTableViewController : PhotoTableViewController
@property (nonatomic, strong) NSDictionary *topPlaceToSearch; // passed in city to search for places
@end
