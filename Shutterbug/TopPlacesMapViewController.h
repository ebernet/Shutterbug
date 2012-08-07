//
//  TopPlacesMapViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


@interface TopPlacesMapViewController : UIViewController <MKMapViewDelegate>
@property (nonatomic, strong) NSArray *placesForMaps;               // of id <NSDictionary>. This is a linear list. Gets set by parent.
@property (nonatomic, strong) NSDictionary *localeToDisplay;        // Advertise currently selected location, used by parent to pass on in nav.

- (void)updateMapView;

@end
