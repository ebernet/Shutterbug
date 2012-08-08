//
//  MapViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class MapViewController;

@protocol MapViewControllerDelegate <NSObject>
- (UIImage *)mapViewController:(MapViewController *)sender imageForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapViewController:(MapViewController *)sender currentPhoto:(NSDictionary *)photo;
@end

@interface MapViewController : UIViewController <MKMapViewDelegate>   // tried to update when coming out of seep based in prefs
                                                                      // had this also be a UIApplicationDelegate
@property (nonatomic, strong) NSArray *photos;                  // of id <NSDictionary>. List of photos
@property (nonatomic, strong) NSDictionary *photoToDisplay;

@property (nonatomic, weak) id <MapViewControllerDelegate> delegate;

- (void)updateMapView;
@end