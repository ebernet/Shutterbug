//
//  FlickrPlaceAnnotation.h
//  Shutterbug
//
//  Created by Eytan Bernet on 8/5/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

// some defines to get at key values
#define FLICKR_DICT_KEY_CITY    @"_content.city"
#define FLICKR_DICT_KEY_STATE   @"_content.state"
#define FLICKR_DICT_KEY_COUNTRY @"_content.country"


@interface FlickrPlaceAnnotation : NSObject <MKAnnotation>

+ (FlickrPlaceAnnotation *)annotationForPlace:(NSDictionary *)place; // Flickr place dictionary

@property (nonatomic, strong) NSDictionary *place;

@end
