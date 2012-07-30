//
//  DetailViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplitViewBarButtonItemPresenter.h"

@interface DetailViewController : UIViewController <SplitViewBarButtonItemPresenter>
@property (nonatomic, strong) NSDictionary *photoDictionary;
@end
