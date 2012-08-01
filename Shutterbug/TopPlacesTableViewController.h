//
//  TopPlacesTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/26/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>

// some defines to get at key values
#define FLICKR_DICT_KEY_CITY    @"_content.city"
#define FLICKR_DICT_KEY_STATE   @"_content.state"
#define FLICKR_DICT_KEY_COUNTRY @"_content.country"

@interface TopPlacesTableViewController : UITableViewController
@property (nonatomic, strong) NSArray *places;  // of Flickr places
@end
