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

- (NSMutableArray *)cities
{
    if (!_cities) _cities = [[NSMutableArray alloc] init];
    return _cities;
}

- (id)initWithCountryName:(NSString *)name
{
    self = [super init];
    if (self) {
        self.country = name;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    Countries *new = [[Countries allocWithZone:zone] init];
    if (new) {
        new.country = [NSString stringWithString:self.country];
        new.cities = [[NSMutableArray allocWithZone:zone] initWithArray:self.cities copyItems:YES];
    }
    return new;
}
@end
