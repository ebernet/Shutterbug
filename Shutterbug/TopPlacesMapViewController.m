//
//  MapViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "TopPlacesMapViewController.h"
#import "FlickrPlaceAnnotation.h"
#import "FlickrFetcher.h"
#import <MapKit/MapKit.h>

@interface TopPlacesMapViewController ()
@end

@implementation TopPlacesMapViewController
@synthesize mapView = _mapView;
@synthesize localeToDisplay = _localeToDisplay;
@synthesize annotations = _annotations;
@synthesize placesForMaps = _placesForMaps;

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *aView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MapVC"];
    if (!aView) {
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapVC"];
        aView.canShowCallout = YES;
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        // could put a rightCalloutAccessoryView here
    }
    aView.annotation = annotation;
    return aView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSDictionary *locale = [self.placesForMaps objectAtIndex:[self.annotations indexOfObject:[view annotation]]];
    
    self.localeToDisplay = locale;
    
    // Now do segue to bring up the a list of photos at the current location
    [self.parentViewController performSegueWithIdentifier:@"Show Photos At Place" sender:self.parentViewController];
}

- (IBAction)changeMapStyle:(id)sender {

    switch ([sender selectedSegmentIndex]) {
        case 0:
        {
            [self.mapView setMapType:MKMapTypeStandard];
            break;
        }
        case 1:
        {
            [self.mapView setMapType:MKMapTypeSatellite];
            break;
        }
        default:
        {
            [self.mapView setMapType:MKMapTypeHybrid];
            break;
        } 
    }
}


#pragma mark - Synchronize Model and View


- (NSArray *)mapAnnotations
{
    NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[_placesForMaps count]];
    for (NSDictionary *place in _placesForMaps) {
        [annotations addObject:[FlickrPlaceAnnotation annotationForPlace:place]];
    }
    return annotations;
}

// Set the top places after the thread has copleted, and update the map if it changes
- (void)setPlacesForMaps:(NSArray *)placesForMaps
{
    if (_placesForMaps != placesForMaps) {
        _placesForMaps = placesForMaps;
        self.annotations = [self mapAnnotations];
        if (self.mapView.window)
            [self.mapView setNeedsDisplay];
    }
}

- (void)updateMapView
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    if (self.annotations) [self.mapView addAnnotations:self.annotations];
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    [self updateMapView];
}

- (void)setAnnotations:(NSArray *)annotations
{
    _annotations = annotations;
    [self updateMapView];
}


#pragma mark - MapViewControllerDelegate

- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
