//
//  DetailViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplitViewBarButtonItemPresenter.h"

// Part of the favorites TableViewController
#define RECENTS_KEY @"DetailViewController.Recents"

@interface DetailViewController : UIViewController <SplitViewBarButtonItemPresenter>
@property (nonatomic, strong) NSDictionary *photoDictionary;
@end
