//
//  MapViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


@interface TopPlacesMapViewController : UIViewController <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSArray *annotations;             // of id <MKAnnotation>
@property (nonatomic, strong) NSArray *placesForMaps;           // of id <NSDictionary>. This is a linear list
@property (nonatomic, strong) NSDictionary *localeToDisplay;      // Advertise currently selected location

- (void)updateMapView;

@end
