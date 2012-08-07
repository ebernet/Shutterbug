//
//  FlickrPlaceAnnotation.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/5/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "FlickrPlaceAnnotation.h"
#import "FlickrFetcher.h"

@implementation FlickrPlaceAnnotation

@synthesize place = _place;

+ (FlickrPlaceAnnotation *)annotationForPlace:(NSDictionary *)place
{
    FlickrPlaceAnnotation *annotation = [[FlickrPlaceAnnotation alloc] init];
    annotation.place = place;
    return annotation;
}

#pragma mark - MKAnnotation

- (NSString *)title
{
    return [self.place objectForKey:FLICKR_DICT_KEY_CITY];
}

- (NSString *)subtitle
{
    return [self.place valueForKeyPath:FLICKR_DICT_KEY_STATE];
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [[self.place objectForKey:FLICKR_LATITUDE] doubleValue];
    coordinate.longitude = [[self.place objectForKey:FLICKR_LONGITUDE] doubleValue];
    return coordinate;
}
@end