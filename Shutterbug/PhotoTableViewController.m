//
//  RecentPhotoTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "PhotoTableViewController.h"
#import "FlickrFetcher.h"

@interface PhotoTableViewController ()
@property (nonatomic, weak) DetailViewController *detailViewController;

// Next step is to load these dynamically and install them depending on which platform I am on
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinnerWhite;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinnerGray;
//@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation PhotoTableViewController
@synthesize photos = _photos;

@synthesize detailViewController = _detailViewController;
@synthesize spinnerWhite = _spinnerWhite;
@synthesize spinnerGray = _spinnerGray;
//@synthesize spinner = _spinner;

- (void)setDetailViewController:(DetailViewController *)detailViewController
{
    if (_detailViewController != detailViewController) {
        _detailViewController = detailViewController;
    }
}

- (void)startSpinner
{
//    [self.spinner startAnimating];
    if (self.splitViewController) {
        // and the iOS is < 5.1 (does not respond to presentsWityGesture) then we want a WHITE activity indicator
        // because the popOvers are black. Otherwise the grey is better
        if ([self.splitViewController respondsToSelector:@selector(presentsWithGesture)]) {
            [self.spinnerGray startAnimating];
        } else {
            [self.spinnerWhite startAnimating];
        }
    } else {
        [self.spinnerGray startAnimating];
    }
}

- (void)stopSpinner
{
//    [self.spinner stopAnimating];
    if (self.splitViewController) {
        // and the iOS is < 5.1 (does not respond to presentsWityGesture) then we want a WHITE activity indicator
        // because the popOvers are black. Otherwise the grey is better
        if ([self.splitViewController respondsToSelector:@selector(presentsWithGesture)]) {
            [self.spinnerGray stopAnimating];
        } else {
            [self.spinnerWhite stopAnimating];
        }
    } else {
        [self.spinnerGray stopAnimating];
    }
}

//- (void)viewDidLoad
//{
//    if (self.splitViewController) {
//        // and the iOS is < 5.1 (does not respond to presentsWityGesture) then we want a WHITE activity indicator
//        // because the popOvers are black. Otherwise the grey is better
//        if ([self.splitViewController respondsToSelector:@selector(presentsWithGesture)]) {
//            self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//        } else {
//            self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//        }
//    } else {
//        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//    }
//    UIView *spinnerHolder = [(UIView *)self.navigationItem. viewWithTag:10];
//    [spinnerHolder addSubview:self.spinner];
//}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.photos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Recent Photos Prototype";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    NSDictionary *photo = [self.photos objectAtIndex:indexPath.row];
    
    NSString *photoTitle = [photo objectForKey:FLICKR_PHOTO_TITLE];
    NSString *photoDescription = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    
    if ([photoTitle isEqualToString:@""]) {
        cell.textLabel.text = ([photoDescription isEqualToString:@""])?@"Unknown":photoDescription;
        cell.detailTextLabel.text = @"";
    } else {
        cell.textLabel.text = photoTitle;
        cell.detailTextLabel.text = photoDescription;
    }
    
    return cell;
}

// Only called on iPhone, not on iPad
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Photo"]) {
        DetailViewController *destVC = segue.destinationViewController;
        destVC.photoDictionary = self.photoToDisplay;
    }
}

// Are we in a split view controller? If so, return detail view controller if it is a DetailViewController
- (DetailViewController *)splitViewDetailViewController
{
    // splitViews always have just two, detail is lastObject
    id gvc = [self.splitViewController.viewControllers lastObject];
    if (![gvc isKindOfClass:[DetailViewController class]]) gvc = nil;
    return gvc;
}

// For pressing an image from list item in table.
// Each subclass handles it a little differently, one adding it
// to recents and one not
- (void)showPhoto
{
    // iPad? Just set the image
    if ([self splitViewDetailViewController]) {
        [[self splitViewDetailViewController] setPhotoDictionary:self.photoToDisplay];
    } else { // iPhone? Transition to image
        [self performSegueWithIdentifier:@"Show Photo" sender:self];
    }
}

@end
