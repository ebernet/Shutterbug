//
//  FlickrPlaceAnnotation.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/5/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FlickrPlaceAnnotation : NSObject <MKAnnotation>

+ (FlickrPlaceAnnotation *)annotationForPlace:(NSDictionary *)place; // Flickr place dictionary

@property (nonatomic, strong) NSDictionary *place;
@end