//
//  RotatableViewController.h
//  Calculator
//
//  Created by Eytan Bernet on 7/13/12.
//  Copyright (c) 2012 Computers For Peace. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RotatableViewController : UITableViewController <UISplitViewControllerDelegate>
@property (nonatomic, strong) UIPopoverController *popoverController;
@end
