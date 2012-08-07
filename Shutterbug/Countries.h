//
//  Countries.h
//  Shutterbug
//
//  Helper class to store the array of countries and for each country
//  have the name as a string and all the citiy records as an array of cities.
//
//  Created by Eytan Bernet on 7/27/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Countries : NSObject

@property (nonatomic, strong) NSMutableArray *cities;   // Array of cities to store in the country
@property (nonatomic, strong) NSString *country;        // and the name of the country
@end
