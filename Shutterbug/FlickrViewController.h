//
//  FlickrViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FlickrViewController : UIViewController
@property (nonatomic, strong) NSArray *photos;  // of Flickr photo dictionaries
@property (nonatomic, strong) NSDictionary *photoToDisplay;
@property (nonatomic) BOOL currentlyShowingMap;

// Made this public so as I could do an addToRecents when doing a showPhoto when showing 1st time
- (void)showPhoto;
- (void)startSpinner;
- (void)stopSpinner;
- (void)addToRecents;

@end
