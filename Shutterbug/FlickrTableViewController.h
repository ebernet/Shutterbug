//
//  FlickrTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlickrTableViewController : UITableViewController
@property (nonatomic,strong) NSArray *photos;           // of Flickr photos, when used inside image viewers
@property (nonatomic, weak) NSDictionary *localeToDisplay;      // Advertise currently selected location
@property (nonatomic, strong) NSDictionary *photoToDisplay;
@end
