//
//  MapViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "MapViewController.h"
#import "FlickrPhotoAnnotation.h"
#import "FlickrViewController.h"
#import "FlickrFetcher.h"
#import <MapKit/MapKit.h>

@interface MapViewController () <FlickrMapViewControllerDelegate>
@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize annotations = _annotations;
@synthesize photos = _photos;
@synthesize photoToDisplay = _photoToDisplay;

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *aView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MapVC"];
    if (!aView) {
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapVC"];
        aView.canShowCallout = YES;
        aView.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    
    aView.annotation = annotation;
    [(UIImageView *)aView.leftCalloutAccessoryView setImage:nil];
    
    return aView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)aView
{
    // Unsure how to test this, because it is so fast!, I am assuming that despite dequeue and
    // reuse of Annotation Views, the pointer to the leftCallOutAccessoryView changes with different
    // callouts...
    
    __block UIImage *image;
    __block UIImageView *currentImageViewPointer = (UIImageView *)aView.leftCalloutAccessoryView;
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("thumbnail downloader", NULL);
    dispatch_async(downloadQueue, ^{
        image = [self mapViewController:self imageForAnnotation:aView.annotation];
        dispatch_async(dispatch_get_main_queue(), ^{
            // If the left call out accessory at this point is the same as the one before we made the call,
            // then set the imageon the main thread.
            if ([(UIImageView *)aView.leftCalloutAccessoryView isEqual:currentImageViewPointer]) {
                [(UIImageView *)aView.leftCalloutAccessoryView setImage:image];
            }
        });
    });
    dispatch_release(downloadQueue);
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSDictionary *photo = [self.photos objectAtIndex:[self.annotations indexOfObject:[view annotation]]];
    self.photoToDisplay = photo;
    [(FlickrViewController *)self.parentViewController showPhoto];
//    [self.parentViewController performSegueWithIdentifier:@"Show Photo" sender:self];
}

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        self.annotations = [self mapAnnotations];
        if (self.mapView.window)
            [self.mapView setNeedsDisplay];
    }
}

- (NSArray *)mapAnnotations
{
    if (self.photos) {
        NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[self.photos count]];
        for (NSDictionary *photo in self.photos) {
            [annotations addObject:[FlickrPhotoAnnotation annotationForPhoto:photo]];
        }
        return annotations;
    } else {
        return nil;
    }
}


#pragma mark - Synchronize Model and View

- (void)updateMapView
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    if (self.annotations) [self.mapView addAnnotations:self.annotations];
    
    if (self.annotations) {
        // Need to figure algorithm for span
        
        __block CLLocationCoordinate2D min = [[self.annotations objectAtIndex:0] coordinate];
        __block CLLocationCoordinate2D max = min;
        
        
        [self.annotations enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop){
            // We want to throw an error if it is not a dictionary
            assert([element isKindOfClass:[FlickrPhotoAnnotation class]]);
            FlickrPhotoAnnotation *location = element;
            
            // Get the country name for each element
            CLLocationCoordinate2D currentCcoordinate = location.coordinate;
            
            min.latitude = MIN(min.latitude, currentCcoordinate.latitude);
            min.longitude = MIN(min.longitude, currentCcoordinate.longitude);
            
            max.latitude = MAX(max.latitude, currentCcoordinate.latitude);
            max.longitude = MAX(max.longitude, currentCcoordinate.longitude);
        }];
        
        
        
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake((max.latitude + min.latitude) / 2.0, (max.longitude + min.longitude) / 2.0);
        MKCoordinateSpan span = MKCoordinateSpanMake(max.latitude - min.latitude, max.longitude - min.longitude);
        MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
        
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
        
    }
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

#pragma mark - MapViewControllerDelegate

- (UIImage *)mapViewController:(MapViewController *)sender imageForAnnotation:(id <MKAnnotation>)annotation
{
    FlickrPhotoAnnotation *fpa = (FlickrPhotoAnnotation *)annotation;
    NSURL *url = [FlickrFetcher urlForPhoto:fpa.photo format:FlickrPhotoFormatSquare];
    NSData *data = [NSData dataWithContentsOfURL:url];
    return data ? [UIImage imageWithData:data] : nil;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.annotations = [self mapAnnotations];
}

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
