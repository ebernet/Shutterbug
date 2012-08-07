//
//  FlickrViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/26/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "MapViewController.h"
#import "FlickrViewController.h"
#import "FlickrTableViewController.h"
#import "MapViewController.h"
#import "DetailViewController.h"

@interface FlickrViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *listOrMap;
@property (nonatomic,weak) FlickrTableViewController *tableViewController;
@property (nonatomic,weak) MapViewController *mapViewController;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic, strong) id currentViewController; // Holds the currently active view Controller
@property (strong, nonatomic) UIActivityIndicatorView *spinner; // Strong because I place it, it is not in a NIB!
@property (weak, nonatomic) IBOutlet UIView *spinnerContainer;  // Weak because it is in the storyboard!
@end

@implementation FlickrViewController

@synthesize mapViewController = _mapViewController;
@synthesize tableViewController = _tableViewController;
@synthesize listOrMap = _listOrMap;
@synthesize contentView = _contentView;
@synthesize photos = _photos;
@synthesize photoToDisplay = _photoToDisplay;
@synthesize currentlyShowingMap = _currentlyShowingMap;



// Store photo in recents
// COULD store just the photo ID, but the entire record is not very large
// And like this I don't need to retrieve name informatio again, etc.
- (void)addToRecents {
    // Get recents array from defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *recents = [[defaults objectForKey:RECENTS_KEY] mutableCopy];
    // If we don't have one, create one
    if (!recents) recents = [NSMutableArray array];
    
    // So the code below works. Question, should I have iterrated through he list
    // and used the isEqualToDictionary: call on each element? How could these two be the same?
    
    // NOTE: sontainsObject does an isEqual, NOT a ==
    
    // If there, move it to top
    if ([recents containsObject:self.photoToDisplay]) {
        // by deleting the old one
        [recents removeObject:self.photoToDisplay];
    }
    // Now add it at the top
    [recents insertObject:self.photoToDisplay atIndex:0];
    
    // However, if we have more than 20 now, delete the last one
    if ([recents count] > 20) [recents removeObject:[recents lastObject]];
    
    // And synchronize the saving
    [defaults setObject:recents forKey:RECENTS_KEY];
    [defaults synchronize];
}

#pragma mark - Spinner components

// Create the appropriate spinner depending on platform
- (UIActivityIndicatorView *)spinner
{
    if (_spinner == nil) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _spinner;
}

- (void)startSpinner
{
    [self.spinner startAnimating];
}

- (void)stopSpinner
{
    [self.spinner stopAnimating];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.photos count];
}


#pragma mark - Segue/Update methods

// Are we in a split view controller? If so, return detail view controller if it is a DetailViewController
- (DetailViewController *)splitViewDetailViewController
{
    // splitViews always have just two, detail is lastObject
    id gvc = [self.splitViewController.viewControllers lastObject];
    if (![gvc isKindOfClass:[DetailViewController class]]) gvc = nil;
    return gvc;
}

// Only called on iPhone, not on iPad
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Photo"]) {
        DetailViewController *destVC = segue.destinationViewController;
        destVC.photo = self.photoToDisplay;
    }
}

// For pressing an image from list item in table.
// Each subclass handles it a little differently, one adding it
// to recents and one not
- (void)showPhoto
{
    if (self.currentlyShowingMap) {
        self.photoToDisplay = self.mapViewController.photoToDisplay;
    } else {
        self.photoToDisplay = self.tableViewController.photoToDisplay;
    }
    [self addToRecents];

    // iPad? Just set the image
    if ([self splitViewDetailViewController]) {
        [[self splitViewDetailViewController] setPhoto:self.photoToDisplay];
        // And dismiss the popOver/slideOut
        [[[self splitViewDetailViewController] myPopoverController] dismissPopoverAnimated:YES];
    } else { // iPhone? Transition to image
        [self performSegueWithIdentifier:@"Show Photo" sender:self];
    }
}

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        if (self.currentlyShowingMap) {
            self.mapViewController.photos = _photos;
            [self.mapViewController updateMapView];
        } else {
            self.tableViewController.photos = _photos;
            [self.tableViewController.tableView reloadData];
        }
    }
}

- (MapViewController *)mapViewController
{
    if (_mapViewController == nil) {
        _mapViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mapViewControllerID"];
    }
    return _mapViewController;
}

- (FlickrTableViewController *)tableViewController
{
    if (_tableViewController == nil) {
        _tableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"tableViewControllerID"];
    }
    return _tableViewController;
}

- (id)viewControllerForSegmentIndex:(NSInteger)index {
    id vc;
    switch (index) {
        case 0:
            vc = self.tableViewController;
            break;
        case 1:
            vc = self.mapViewController;
            break;
    }
    return vc;
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    UIViewController *vc = [self viewControllerForSegmentIndex:sender.selectedSegmentIndex];
    if ([vc isEqual:self.mapViewController]) {
        self.mapViewController.photos = [self photos];
        [self.mapViewController updateMapView];
        self.currentlyShowingMap = YES;
    } else if ([vc isEqual:self.tableViewController]) {
        self.tableViewController.photos = [self photos];
        [self.tableViewController.tableView reloadData];
        self.currentlyShowingMap = NO;
    }

    [self addChildViewController:vc];
    [self transitionFromViewController:self.currentViewController
                      toViewController:vc
                              duration:0   //don't really want to see transition
                               options:UIViewAnimationOptionLayoutSubviews
                            animations:^{
        [((UIViewController *)self.currentViewController).view removeFromSuperview];
        vc.view.frame = self.contentView.bounds;
        [self.contentView addSubview:vc.view];
    } completion:^(BOOL finished) {
        [vc didMoveToParentViewController:self];
        [self.currentViewController removeFromParentViewController];
        self.currentViewController = vc;
    }];
}

#pragma mark - UIViewController lifecycle

// Force a refresh. Trying to get data before the interface is even up...
// This is why I made th refreshButton an outles - since the code that gets called to refresh
// is usually from a button, and I replace the button with the spinner, I need to explicitly send
// it the button. By making it an outlet and declaring it I have access to it here.
- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.spinnerContainer addSubview:self.spinner];

    if (self.currentlyShowingMap) {
        self.listOrMap.selectedSegmentIndex = 1;
        self.mapViewController = [self viewControllerForSegmentIndex:1];
        [self addChildViewController:self.mapViewController];
        self.mapViewController.view.frame = self.contentView.bounds;
        [self.contentView addSubview:self.mapViewController.view];
        self.currentViewController = self.mapViewController;
        self.currentlyShowingMap = YES;
    } else {
        self.listOrMap.selectedSegmentIndex = 0;
        self.tableViewController = [self viewControllerForSegmentIndex:0];
        [self addChildViewController:self.tableViewController];
        self.tableViewController.view.frame = self.contentView.bounds;
        [self.contentView addSubview:self.tableViewController.view];
        self.currentViewController = self.tableViewController;
        self.currentlyShowingMap = NO;
    }
}

- (void)viewDidUnload
{
    [self setListOrMap:nil];
    [self setContentView:nil];
    [super viewDidUnload];
}

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
@end
