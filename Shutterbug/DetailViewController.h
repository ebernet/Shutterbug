//
//  DetailViewController.h
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplitViewBarButtonItemPresenter.h"

@interface DetailViewController : UIViewController <SplitViewBarButtonItemPresenter, UISplitViewControllerDelegate>
@property (nonatomic, strong) NSDictionary *photo;
@end
