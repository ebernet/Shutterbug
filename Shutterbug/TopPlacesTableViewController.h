//
//  FlickrTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TopPlacesTableViewController : UITableViewController
@property (nonatomic,strong) NSArray *places;           // of Flickr places, grouped by countries, for when used in Top Places
@property (nonatomic, strong) NSDictionary *localeToDisplay;      // Advertise currently selected location
@end
