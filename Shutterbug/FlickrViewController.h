//
//  FlickrViewController.h
//  Shutterbug
//
//  This is the superclass for all picture related UIViewControllers, both the ones at a location
//  and the recents. Subclassed to decide how to load the list.
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>

// To store/retrieve the recents
#define RECENTS_KEY @"DetailViewController.Recents"

@interface FlickrViewController : UIViewController
@property (nonatomic, strong) NSArray *photos;          // of Flickr photo dictionaries
@property (nonatomic, strong) NSDictionary *photoToDisplay;
@property (nonatomic) BOOL currentlyShowingMap;

// Made these public so they can be called by subclass and by subview Controllers.
- (void)showPhoto;
- (void)startSpinner;
- (void)stopSpinner;
@end