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

// I load a White or Gray spinner, depending on whether I am on an iPhone or an iPad,
// and on the iPad on iOS 5 or 5.1 because they have different colored toolbars and
// white is needed on the darker ones, and gray on the lighter ones. To do that I have an
// outlet to the UIView in the toolbar I want to contain the spinner, and I create
//the right one and embed it in the container.
@property (strong, nonatomic) UIActivityIndicatorView *spinner; // Strong because I place it, it is not in a NIB!
@property (weak, nonatomic) IBOutlet UIView *spinnerContainer;  // Weak because it is in the storyboard!
@end

@implementation PhotoTableViewController
@synthesize photos = _photos;

@synthesize spinner = _spinner;
@synthesize spinnerContainer = _spinnerContainer;

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        if (self.tableView.window) [self.tableView reloadData];
    }
}

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
        // Are you on an iPad, AND running 5.1 (presentsWithGesture arrives with 5.1)
        if ((self.splitViewController) && (![self.splitViewController respondsToSelector:@selector(presentsWithGesture)])) {
            _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        } else {
            _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        }
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

// Set the name of the photo and/or description
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

#pragma mark - Table view delegate

// We need to do this uniquely because we only want to add to recents when viewing images
// from the FlickrPhotoTableViewController, not from RecentPhotoTableViewController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the current photo from the DB
    self.photoToDisplay = [self.photos objectAtIndex:indexPath.row];
    [self showPhoto];
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
    // iPad? Just set the image
    if ([self splitViewDetailViewController]) {
        [[self splitViewDetailViewController] setPhoto:self.photoToDisplay];
        // And dismiss the popOver/slideOut
        [[[self splitViewDetailViewController] myPopoverController] dismissPopoverAnimated:YES];
    } else { // iPhone? Transition to image
        [self performSegueWithIdentifier:@"Show Photo" sender:self];
    }
}

#pragma mark - view lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// viewDidLoad is overridden to add in the spinner
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.spinnerContainer addSubview:self.spinner];
}

- (void)viewDidUnload {
    [self setSpinner:nil];
    [super viewDidUnload];
}
@end
