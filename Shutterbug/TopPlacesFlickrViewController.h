//
//  TopPlacesFlickrViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "FlickrViewController.h"

@interface TopPlacesFlickrViewController : UIViewController
@property (nonatomic, strong) NSDictionary *localeToDisplay;                  // What place do we want to show photos for
@end
