//
//  PhotosViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "FlickrViewController.h"

@interface PhotosViewController : FlickrViewController
@property (nonatomic, strong) NSDictionary *localeToDisplay; // passed in city to search for places
@end
