//
//  TopPlacesFlickrViewController.h
//  Shutterbug
//
//  This is the TopPlaces parent view controller. It uses a UISegmentedControl to switch
//  between two sub UIVewControlls, a UITableViewControl and a UIViewController that contains
//  a map view. We do this to separate the work for the two between two files. Initially I had
//  two views that I hid and showed, but that required ALL the controlling code for the parent,
//  the Table, and the Map to all abe in one file. This is cleaner
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "FlickrViewController.h"

@interface TopPlacesFlickrViewController : UIViewController
@end
