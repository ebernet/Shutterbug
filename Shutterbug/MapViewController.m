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

@interface MapViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSArray *annotations;             // of id <MKAnnotation>
@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize annotations = _annotations;
@synthesize photos = _photos;
@synthesize photoToDisplay = _photoToDisplay;
@synthesize delegate = _delegate;

#pragma mark - MKMapViewDelegate

#define SHOW_IMAGES_FOR_PINS @"show_images_for_pins"
#define PIN_DIMENSIONS 15

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *aView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MapVC"];
    if (!aView) {
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapVC"];
        aView.canShowCallout = YES;
        // Allow space for thumbnail in left accessory view
        aView.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];

// Experimental image for pin

        if ([[NSUserDefaults standardUserDefaults] boolForKey:SHOW_IMAGES_FOR_PINS]) {
            // This chunk of code below loads up the thumbnail as a pin. Might be nicer to put it in a grey rectangle or something.
            // Right now I think a pin works better...
            aView.image = [UIImage imageNamed:@"smallcallout.png"];
            __block UIImage *pinImage;

            aView.image = pinImage;
            aView.opaque = NO;
            dispatch_queue_t downloadQueue = dispatch_queue_create("thumbnail downloader", NULL);
            dispatch_async(downloadQueue, ^{
                pinImage = [self.delegate mapViewController:self imageForAnnotation:aView.annotation];
                dispatch_async(dispatch_get_main_queue(), ^{
        
                    // Resize the thumbnail into 15/15
                    CGRect resizeRect = CGRectMake(0, 0, PIN_DIMENSIONS, PIN_DIMENSIONS);
                    resizeRect.origin = CGPointZero;
                    UIGraphicsBeginImageContext(resizeRect.size);
                    [pinImage drawInRect:resizeRect];
                    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    aView.image = resizedImage;
                });
            });
            dispatch_release(downloadQueue);
            
            // This is the end of what you would cut out...
        }
//*** end of image pins

    
    }
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
        image = [self.delegate mapViewController:self imageForAnnotation:aView.annotation];
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

    [self.delegate mapViewController:self currentPhoto:photo];
    
    [(FlickrViewController *)self.parentViewController showPhoto];
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

- (void)updateMapView
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    if (self.annotations) [self.mapView addAnnotations:self.annotations];
    
    if (self.annotations) {
        // Use 1st image as starting point
        __block CLLocationCoordinate2D min = [[self.annotations objectAtIndex:0] coordinate];
        __block CLLocationCoordinate2D max = min;
        
        
        [self.annotations enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop){

            // Cast to a FlickrPhotoAnnotation so as we can get at coordinate
            FlickrPhotoAnnotation *location = element;
            
            // Get the location for each element
            CLLocationCoordinate2D currentCcoordinate = location.coordinate;
            
            // See if we have found a new min/max
            min.latitude = MIN(min.latitude, currentCcoordinate.latitude);
            min.longitude = MIN(min.longitude, currentCcoordinate.longitude);
            
            max.latitude = MAX(max.latitude, currentCcoordinate.latitude);
            max.longitude = MAX(max.longitude, currentCcoordinate.longitude);
        }];
        
        // Half way between min/max with a little buffer in span
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake((max.latitude + min.latitude) / 2.0, (max.longitude + min.longitude) / 2.0);
        MKCoordinateSpan span = MKCoordinateSpanMake((max.latitude - min.latitude) + (max.latitude - min.latitude)/10, (max.longitude - min.longitude) + (max.longitude - min.longitude)/10);
        MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
        
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
        
    }
}

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[self.photos count]];
        for (NSDictionary *photo in self.photos) {
            [annotations addObject:[FlickrPhotoAnnotation annotationForPhoto:photo]];
        }
        self.annotations = annotations;
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

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

//- (void)applicationDidBecomeActive:(UIApplication *)application
//{
//    [self updateMapView];
//}

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
@end