//
//  TopPlacesTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/26/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "TopPlacesViewController.h"
#import "FlickrPhotoViewController.h"
#import "FlickrFetcher.h"
#import "Countries.h"
#import "FlickrPlaceAnnotation.h"
#import <MapKit/MapKit.h>

@interface TopPlacesViewController ()
@property (nonatomic, weak) NSDictionary *localeToDisplay;                  // What place do we want to show photos for
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;        // Need this for spinner reverting to refresh. See viewDidLoad
@property (nonatomic,weak) IBOutlet UITableView *tableView;
@property (nonatomic,weak) IBOutlet MKMapView *mapView;
@property (nonatomic,strong) NSArray *places;  // of Flickr places
@property (nonatomic,strong) NSArray *placesForMaps;  // of Flickr places
@property (weak, nonatomic) IBOutlet UISwitch *showMapsToggle;
@property (nonatomic) BOOL currentlyShowingMap;
@end

@implementation TopPlacesViewController

@synthesize places = _places;
@synthesize placesForMaps = _placesForMaps;
@synthesize localeToDisplay = _localeToDisplay;
@synthesize refreshButton = _refreshButton;
@synthesize mapView = _mapView;
@synthesize annotations = _annotations;
@synthesize showMapsToggle = _showMapsToggle;
@synthesize currentlyShowingMap = _currentlyShowingMap;


// This is called when you hit the refresh button. Also called 1st time you open
// up the top places panel on iPad or when launching on iPhone
- (void)loadTopPlaces {

    // Get top places
    NSArray *places = [FlickrFetcher topPlaces];

    // Now modify it to have location info broken out
    NSMutableArray *enhancedPlacesList = [[NSMutableArray alloc] init];

    // This will execute this code on each element in the array. It will modify the data structure
    // to have better (easier to parse) location info (in regards to country, city, state)
    [places enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {
        
        // Get the current entry
        NSMutableDictionary *thisEntry = [element mutableCopy];
        
        // split on comma, and start with unknown values for 3 fields
        [thisEntry setValue:@"" forKey:FLICKR_DICT_KEY_CITY];
        [thisEntry setValue:@"" forKey:FLICKR_DICT_KEY_STATE];
        [thisEntry setValue:@"" forKey:FLICKR_DICT_KEY_COUNTRY];
        
        // Get the _content field from API. This SHOULD contain city, state, country but
        // any or all of the fields can be empty
        NSArray *locationParts = [[thisEntry objectForKey:@"_content"] componentsSeparatedByString:@", "];
        switch ([locationParts count]) {
            case 0:    // shouldn't happen, if no commas, resulting list should have one entry
                break;
            case 1:    // no commas, just use as city
                [thisEntry setValue:[locationParts objectAtIndex:0] forKey:FLICKR_DICT_KEY_CITY];
                break;
            case 2:    // one commas, just city+country?
                [thisEntry setValue:[locationParts objectAtIndex:0] forKey:FLICKR_DICT_KEY_CITY];
                [thisEntry setValue:[locationParts objectAtIndex:1] forKey:FLICKR_DICT_KEY_COUNTRY];
                break;
            default:   // two or more commas, use first three items
                [thisEntry setValue:[locationParts objectAtIndex:0] forKey:FLICKR_DICT_KEY_CITY];
                [thisEntry setValue:[locationParts objectAtIndex:1] forKey:FLICKR_DICT_KEY_STATE];
                [thisEntry setValue:[locationParts objectAtIndex:2] forKey:FLICKR_DICT_KEY_COUNTRY];
        }
        
        [enhancedPlacesList addObject:thisEntry];
    }];
    
    // Okay, so now we have a list of places, not sorted yet. We use it for the annotations!
   
    
    // Parse and sort places, still on another thread. This will return an array
    // of countries rather than of all the locations. Each country will have an
    // array of cities
    NSArray *finalizedPlaces = [TopPlacesViewController sortFlickrTopPlaces:enhancedPlacesList];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.places = finalizedPlaces;              // Sorted list, with countries
        self.placesForMaps = enhancedPlacesList;    // Sorted list, no countries, but city/country/state broken out
    });
}


// This is called when you hit the refresh button. Also called 1st time you open
// up the top places panel on iPad or when launching on iPhone
- (IBAction)refresh:(id)sender {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

    [spinner startAnimating];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];

    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr places downloader", NULL);
    dispatch_async(downloadQueue, ^{
        [self loadTopPlaces];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem = sender;
        });
    });
    dispatch_release(downloadQueue);
}

// Bulk of work happens here after retrieving TopPlaces
+ (NSArray *)sortFlickrTopPlaces:(NSArray *)enhancedPlacesList
{
    // If the call to the API failed and we got nothing back, do not try and sort it
    // and just return a blank list
    if (!enhancedPlacesList) return nil;
    
    // Otherwise, make a mutable copy that we can sort
    NSMutableArray *sortedPlacesList = [enhancedPlacesList mutableCopy];
    NSMutableArray *countryList = [[NSMutableArray alloc] init];
        
    // now sort by country, city, state (in that order)
    
    // The arguments to the block are two objects to compare.
    // The block returns an NSComparisonResult value to denote the ordering of the two objects.
    
    [sortedPlacesList sortUsingComparator:^NSComparisonResult(id element1, id element2){
        
        NSComparisonResult result;
        
        // If either of these are not dictionaries, then something catastrophic has happened
        assert([element1 isKindOfClass:[NSDictionary class]]);
        assert([element2 isKindOfClass:[NSDictionary class]]);

        // use NSDictionary so as we don't need to cast in calls
        NSDictionary *locale1 = element1;
        NSDictionary *locale2 = element2;
        
        // 1st compare country
        result = [[locale1 valueForKey:FLICKR_DICT_KEY_COUNTRY] localizedCaseInsensitiveCompare:[locale2 valueForKey:FLICKR_DICT_KEY_COUNTRY]];
        // If countries are the same, compare on city...
        if (result == NSOrderedSame) {
            result = [[locale1 valueForKey:FLICKR_DICT_KEY_CITY] localizedCaseInsensitiveCompare:[locale2 valueForKey:FLICKR_DICT_KEY_CITY]];
        }
        // If cities are the same, compare on state
        if (result == NSOrderedSame) {
            result = [[locale1 valueForKey:FLICKR_DICT_KEY_STATE] localizedCaseInsensitiveCompare:[locale2 valueForKey:FLICKR_DICT_KEY_STATE]];
        }
        
        // Now return the result of the compare.
        return result;
    }];
    
    // Okay, at this point we have sorted all the places by country. We need to split
    // the list into a list of countries that each has a list of cities for sections in table view
        
    // So these block variables can be modified in the scope of the block
    // and be accessed outside the block as well. We need to do this to keep
    // track of the country we are on, and to create the country chunks
    
    __block NSString *priorCountry = nil; // Keep track of country name
    // Want to create a new entry in the countryList for each new one, a
    // group that includes all the cities in that country
    __block Countries *citiesInCountryList = [[Countries alloc] init];
    
    [sortedPlacesList enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop){
        // We want to throw an error if it is not a dictionary
        assert([element isKindOfClass:[NSDictionary class]]);
        NSDictionary *locationDict = element;
        
        // Get the country name for each element
        NSString *currentCountryName = [locationDict valueForKey:FLICKR_DICT_KEY_COUNTRY];
        
        // If we have already had a prior contry, and they are different (regardless of case)
        if (priorCountry && [currentCountryName localizedCaseInsensitiveCompare:priorCountry] != NSOrderedSame) {
            // add the previous group of cities in a country to the countryList
            [countryList addObject:[citiesInCountryList copy]];
            // and start up a new country to hold these cities
            citiesInCountryList = [[Countries alloc] init];
        }
        // Set the country name for this list, it's alright that we set it again each
        // time through even if it is the same country
        citiesInCountryList.country = currentCountryName;
        // Add the Top Places record for each location
        [citiesInCountryList.cities addObject:[locationDict copy]];
        // and set the current country so as we can segent by country
        priorCountry = currentCountryName;
    }];
    // When we finish the block, we still have the final country NOT added...
    // So add that last grouping!
    [countryList addObject:[citiesInCountryList copy]];
    
    // and return our list of countries
    return countryList;
}

// Set the top places after the thread has copleted, and update the table if it changes
- (void)setPlaces:(NSArray *)places
{
    if (_places != places) {
        _places = places;
        if (self.tableView.window) {
                [self.tableView reloadData];
        }
        if (self.mapView.window) {
            [self updateMapView];
        }
    }
}

// Set the top places after the thread has copleted, and update the map if it changes
- (void)setPlacesForMaps:(NSArray *)placesForMaps
{
    if (_placesForMaps != placesForMaps) {
        _placesForMaps = placesForMaps;
        self.annotations = [self mapAnnotations];
        if (self.mapView.window) [self.mapView setNeedsDisplay];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of countries.
    return [self.places count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    // Places is an array of "Countries" objects. They each have a name, and an array of cities.
    return [[[self.places objectAtIndex:section] cities] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Top Places Prototype";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    // 1st, get the country object from the array of countries
    Countries *country = [self.places objectAtIndex:indexPath.section];
    // Now for the country, get the array of locales.
    NSArray *cities = country.cities;
    // For each locale, get the city and the state
    NSDictionary *locale = [cities objectAtIndex:indexPath.row];
    cell.textLabel.text = [locale valueForKey:FLICKR_DICT_KEY_CITY];
    cell.detailTextLabel.text = [locale valueForKey:FLICKR_DICT_KEY_STATE];

    return cell;
}

// Get the header from the country field in the array of countries
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.places objectAtIndex:section] country];
}

// This segue is called for both iPhone AND iPad since it is in the masterController on the iPad
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Photos At Place"]) {
        FlickrPhotoViewController *destVC = segue.destinationViewController;
        destVC.title = [self.localeToDisplay valueForKey:FLICKR_DICT_KEY_CITY];
        destVC.topPlaceToSearch = self.localeToDisplay;
        destVC.currentlyShowingMap = self.currentlyShowingMap;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the current city from the array of countries. So get a country
    Countries *country = [self.places objectAtIndex:indexPath.section];
    // then its array of locations
    NSArray *cities = country.cities;
    NSDictionary *locale = [cities objectAtIndex:indexPath.row];

    self.localeToDisplay = locale;
    
    // Now do segue to bring up the a list of photos at the current location
    [self performSegueWithIdentifier:@"Show Photos At Place" sender:self];
}

- (NSArray *)mapAnnotations
{
    NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[_placesForMaps count]];
    for (NSDictionary *place in _placesForMaps) {
        [annotations addObject:[FlickrPlaceAnnotation annotationForPlace:place]];
    }
    return annotations;
}


#pragma mark - Synchronize Model and View

- (void)updateMapView
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    if (self.annotations) [self.mapView addAnnotations:self.annotations];
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
        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        // could put a rightCalloutAccessoryView here
    }
    
    aView.annotation = annotation;
    
    return aView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    

    NSDictionary *locale = [self.placesForMaps objectAtIndex:[self.annotations indexOfObject:[view annotation]]];
    
    self.localeToDisplay = locale;
    
    // Now do segue to bring up the a list of photos at the current location
    [self performSegueWithIdentifier:@"Show Photos At Place" sender:self];
}


#pragma mark - MapViewControllerDelegate


- (IBAction)toggleMaps:(UISwitch *)sender {
    if ([sender isOn]) {
        [self.tableView setHidden:YES];
        [self.mapView setHidden:NO];
        self.mapView.delegate = self;
        self.annotations = [self mapAnnotations];
        self.currentlyShowingMap = YES;
    } else {
        [self.tableView setHidden:NO];
        [self.mapView setHidden:YES];
        self.tableView.delegate = self;
        self.currentlyShowingMap = NO;
    }
}

#pragma mark - UIViewController lifecycle

// Force a refresh. Trying to get data before the interface is even up...
// This is why I made th refreshButton an outles - since the code that gets called to refresh
// is usually from a button, and I replace the button with the spinner, I need to explicitly send
// it the button. By making it an outlet and declaring it I have access to it here.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapView.delegate = self;
    [self refresh:self.refreshButton];
    [self.showMapsToggle setOn:self.currentlyShowingMap];
}

- (void)viewDidUnload
{
    [self setRefreshButton:nil];
    [self setShowMapsToggle:nil];
    [super viewDidUnload];
}

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


@end
