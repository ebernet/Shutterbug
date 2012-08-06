//
//  RecentPhotoTableViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "DetailViewController.h"

#import <UIKit/UITableViewController.h>
#import <MapKit/MapKit.h>

// To store/retrieve the recents
#define RECENTS_KEY @"DetailViewController.Recents"

@class ShutterbugViewController;

@protocol MapViewControllerDelegate <NSObject>
- (UIImage *)PhotoTableViewController:(ShutterbugViewController *)sender imageForAnnotation:(id <MKAnnotation>)annotation;
@end

@interface ShutterbugViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate>

// Made this public so as I could do an addToRecents when doing a showPhoto when showing 1st time
- (void)showPhoto;
- (void)startSpinner;
- (void)stopSpinner;
- (void)addToRecents;

@property (nonatomic, strong) NSArray *photos;  // of Flickr photo dictionaries
@property (nonatomic, strong) NSDictionary *photoToDisplay;

@property (nonatomic, strong) NSArray *annotations; // of id <MKAnnotation>
@property (nonatomic, weak) id <MapViewControllerDelegate> delegate;

@property (nonatomic) BOOL currentlyShowingMap;
@end
