//
//  FlickrPhotoTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoTableViewController.h"

@class FlickrPhotoTableViewController;

@protocol FlickrPhotoTableViewControllerDelegate <NSObject> // NSObject is needed if you want to support respondsToSelector:
@optional
- (void)FlickrPhotoTableViewController:(FlickrPhotoTableViewController *)sender chosePhoto:(id)photo;
@end

@interface FlickrPhotoTableViewController : PhotoTableViewController
@property (nonatomic, strong) NSDictionary *topPlaceToSearch; // passed in city to search for places
@property (nonatomic, weak) id <FlickrPhotoTableViewControllerDelegate> delegate;
@end
