//
//  Countries.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/27/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "Countries.h"

@implementation Countries

@synthesize country = _country;
@synthesize cities = _cities;

// Each country has an array of cities
- (NSMutableArray *)cities
{
    if (!_cities) _cities = [[NSMutableArray alloc] init];
    return _cities;
}

// This will make sure that the copy will include all the elements of the cities
// array and not just the pointers to them!!!
- (id)copy
{
    Countries *newLocale = [[Countries alloc] init];
    if (newLocale) {
        // String is just a litteral copy
        newLocale.country = self.country;
        // For the array, however, we need to explicitly copy otherise we get a pointer
        // to the array of cities
        newLocale.cities = [self.cities copy];
    }
    return newLocale;
}
@end