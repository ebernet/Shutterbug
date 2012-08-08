//
//  FlickrTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FlickrTableViewController;

@protocol FlickrTableViewControllerDelegate <NSObject>
@optional
- (void)flickrTableViewController:(FlickrTableViewController *)sender currentPhoto:(NSDictionary *)photo;
@end

@interface FlickrTableViewController : UITableViewController
@property (nonatomic,strong) NSArray *photos;                   // of Flickr photos, when used inside image viewers
@property (nonatomic, weak) NSDictionary *localeToDisplay;      // Advertise currently selected location
@property (nonatomic, strong) NSDictionary *photoToDisplay;

@property (nonatomic, weak) id <FlickrTableViewControllerDelegate> delegate;
@end