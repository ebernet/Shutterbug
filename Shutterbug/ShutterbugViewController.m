//
//  ShutterbugViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "ShutterbugViewController.h"
#import "FlickrFetcher.h"
#import "FlickrPhotoAnnotation.h"
#import <MapKit/MapKit.h>

@interface ShutterbugViewController () <MapViewControllerDelegate>

// I load a White or Gray spinner, depending on whether I am on an iPhone or an iPad,
// and on the iPad on iOS 5 or 5.1 because they have different colored toolbars and
// white is needed on the darker ones, and gray on the lighter ones. To do that I have an
// outlet to the UIView in the toolbar I want to contain the spinner, and I create
//the right one and embed it in the container.
@property (strong, nonatomic) UIActivityIndicatorView *spinner; // Strong because I place it, it is not in a NIB!
@property (weak, nonatomic) IBOutlet UIView *spinnerContainer;  // Weak because it is in the storyboard!
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISwitch *showMapsToggle;
@end

@implementation ShutterbugViewController
@synthesize photos = _photos;
@synthesize currentlyShowingMap = _currentlyShowingMap;

@synthesize spinner = _spinner;
@synthesize spinnerContainer = _spinnerContainer;
@synthesize photoToDisplay = _photoToDisplay;

@synthesize mapView = _mapView;
@synthesize showMapsToggle = _showMapsToggle;
@synthesize annotations = _annotations;
@synthesize delegate = _delegate;

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        self.annotations = [self mapAnnotations];
        if (self.mapView.window) [self.mapView setNeedsDisplay];
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


#pragma mark - Synchronize Model and View

- (void)updateMapView
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    if (self.annotations) [self.mapView addAnnotations:self.annotations];

    
    if (self.annotations && self.mapView.window) {
        // Need to figure algorithm for span
        
        __block CLLocationCoordinate2D min = [[self.annotations objectAtIndex:0] coordinate];
        __block CLLocationCoordinate2D max = min;
        
        
        [self.annotations enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop){
            // We want to throw an error if it is not a dictionary
            assert([element isKindOfClass:[FlickrPhotoAnnotation class]]);
            FlickrPhotoAnnotation *location = element;
            
            // Get the country name for each element
            CLLocationCoordinate2D currentCcoordinate = location.coordinate;
            
            min.latitude = MIN(min.latitude, currentCcoordinate.latitude);
            min.longitude = MIN(min.longitude, currentCcoordinate.longitude);
            
            max.latitude = MAX(max.latitude, currentCcoordinate.latitude);
            max.longitude = MAX(max.longitude, currentCcoordinate.longitude);
        }];
        
        
        
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake((max.latitude + min.latitude) / 2.0, (max.longitude + min.longitude) / 2.0);
        MKCoordinateSpan span = MKCoordinateSpanMake(max.latitude - min.latitude, max.longitude - min.longitude);
        MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
        
        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
        
    }
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    [self updateMapView];
}

- (void)setAnnotations:(NSArray *)annotations
{
    _annotations = annotations;
    [self updateMapView];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *aView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MapVC"];
    if (!aView) {
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapVC"];
        aView.canShowCallout = YES;
        aView.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    
    aView.annotation = annotation;
    [(UIImageView *)aView.leftCalloutAccessoryView setImage:nil];
    
    return aView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)aView
{
    // Need to move this to do on a thread
    
    UIImage *image = [self.delegate PhotoTableViewController:self imageForAnnotation:aView.annotation];
    [(UIImageView *)aView.leftCalloutAccessoryView setImage:image];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSDictionary *photo = [self.photos objectAtIndex:[self.annotations indexOfObject:[view annotation]]];
    
    self.photoToDisplay = photo;
    
    [self showPhoto];
}

- (NSArray *)mapAnnotations
{
    if (self.photos) {
        NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[self.photos count]];
        for (NSDictionary *photo in self.photos) {
            [annotations addObject:[FlickrPhotoAnnotation annotationForPhoto:photo]];
        }
        return annotations;
    } else {
        return nil;
    }
}

#pragma mark - MapViewControllerDelegate

- (UIImage *)PhotoTableViewController:(ShutterbugViewController *)sender imageForAnnotation:(id <MKAnnotation>)annotation
{
    FlickrPhotoAnnotation *fpa = (FlickrPhotoAnnotation *)annotation;
    NSURL *url = [FlickrFetcher urlForPhoto:fpa.photo format:FlickrPhotoFormatSquare];
    NSData *data = [NSData dataWithContentsOfURL:url];
    return data ? [UIImage imageWithData:data] : nil;
}

- (IBAction)toggleMaps:(UISwitch *)sender {
    if ([sender isOn]) {
        [self.tableView setHidden:YES];
        [self.mapView setHidden:NO];
        self.annotations = [self mapAnnotations];
    } else {
        [self.tableView setHidden:NO];
        [self.mapView setHidden:YES];
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
    self.delegate = self;
    self.mapView.delegate = self;
    self.tableView.delegate = self;
    [self.spinnerContainer addSubview:self.spinner];
    [self.showMapsToggle setOn:self.currentlyShowingMap];
    if (self.currentlyShowingMap) {
        [self.tableView setHidden:YES];
        [self.mapView setHidden:NO];
        self.annotations = [self mapAnnotations];
    }
}

- (void)viewDidUnload {
    [self setSpinner:nil];
    [self setShowMapsToggle:nil];
    [super viewDidUnload];
}
@end
