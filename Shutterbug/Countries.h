//
//  Countries.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/27/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Countries : NSObject

@property (nonatomic, strong) NSMutableArray *cities;
@property (nonatomic, strong) NSString *country;

- (id)initWithCountryName:(NSString *)name;

@end
