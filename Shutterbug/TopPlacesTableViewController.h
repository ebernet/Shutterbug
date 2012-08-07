//
//  TopPlacesTableViewController.h
//  Shutterbug
//
//  Similar to the tableviewcontroller I use for images, but since the cell contents are different
//  enough and the type of data is different enough and the files small enough, I keep them separate.
//  Note that I need to pass state information to the parent, so i make a variable local. Maybe
//  could have done with delegation.
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TopPlacesTableViewController : UITableViewController
@property (nonatomic,strong) NSArray *places;                   // of Flickr places, grouped by countries. Set by parent.
@property (nonatomic, strong) NSDictionary *localeToDisplay;    // Advertise currently selected location. Queried by ParentViewController.
@end
