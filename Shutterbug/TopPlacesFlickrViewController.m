//
//  TopPlacesFlickrViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "TopPlacesFlickrViewController.h"
#import "PhotosViewController.h"
#import "MapViewController.h"
#import "FlickrFetcher.h"
#import "Countries.h"

@interface TopPlacesFlickrViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;        // Need this for spinner reverting to refresh. See viewDidLoad
@property (weak, nonatomic) IBOutlet UISegmentedControl *listOrMap;         // The segmented control used to choose ViewControllers to embed
@property (weak, nonatomic) IBOutlet UIView *contentView;                   // Where we embed the controllers
@property (nonatomic,weak) TopPlacesTableViewController *tableViewController;   // The TableViewController...
@property (nonatomic,weak) TopPlacesMapViewController *mapViewController;       // And the MapViewController
@property (nonatomic, strong) id currentViewController; // Holds the currently active view Controller
@property (nonatomic,strong) NSArray *places;           // of Flickr places, grouped by countries
@property (nonatomic,strong) NSArray *placesForMaps;    // of Flickr places - linear list, for maps
@property (nonatomic) BOOL currentlyShowingMap;         // Bool to keep track of what is currently showing
@property (nonatomic, weak) NSDictionary *localeToDisplay;                  // What place do we want to show photos for
@end

@implementation TopPlacesFlickrViewController

@synthesize places = _places;
@synthesize placesForMaps = _placesForMaps;
@synthesize localeToDisplay = _localeToDisplay;
@synthesize refreshButton = _refreshButton;
@synthesize mapViewController = _mapViewController;
@synthesize contentView = _contentView;
@synthesize tableViewController = _tableViewController;
@synthesize listOrMap = _listOrMap;
@synthesize currentlyShowingMap = _currentlyShowingMap;

#pragma mark - Custom Map and Table delegate actions

// These two methods allow the locale to be set from the child controllers
- (void)TopPlacesMapViewController:(TopPlacesMapViewController *)sender currentLocation:(NSDictionary *)location
{
    self.localeToDisplay = location;
}

- (void)TopPlacesTableViewController:(TopPlacesTableViewController *)sender currentLocation:(NSDictionary *)location
{
    self.localeToDisplay = location;
}

#pragma mark - TopPlaces loading and sorting

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
    
    // Okay, so now we have a list of places, not sorted yet. We use it for the annotations (maps)!
    NSArray *finalizedPlaces = [TopPlacesFlickrViewController sortFlickrTopPlaces:enhancedPlacesList];
    
    // Parse and sort places, still on another thread. This will return an array
    // of countries rather than of all the locations. Each country will have an
    // array of cities
    dispatch_async(dispatch_get_main_queue(), ^{
        self.placesForMaps = enhancedPlacesList;    // Sorted list, no countries, but city/country/state broken out
        self.places = finalizedPlaces;              // Sorted list, with countries
    });
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
        if ([self.currentViewController isEqual:self.tableViewController]) {
            self.tableViewController.places = _places;
            [self.tableViewController.tableView reloadData];
        } else if ([self.currentViewController isEqual:self.mapViewController]) {
            self.mapViewController.placesForMaps = self.placesForMaps;
            [self.mapViewController updateMapView];
        }
    }
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

#pragma mark - NavigationController stuff

// This segue is called for both iPhone AND iPad since it is in the masterController on the iPad
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Photos At Place"]) {
        PhotosViewController *destVC = segue.destinationViewController;

/*
        // Now that I have done the delegation, I don't need to do thios weird communication since the locale
        // will have been set for me by the subview controller!
 
 
        // Kind of weird, I know. I am being called by the child ViewController, and then I extract from it the
        // Chosen locale since the TableView or the MapAnnotations are what set the locale....
        if (self.currentlyShowingMap) {
            self.localeToDisplay = self.mapViewController.localeToDisplay;
        } else {
            self.localeToDisplay = self.tableViewController.localeToDisplay;
        }
 */
        // The place will not get seen because we now have the maps/list toggle. Is this important?
        destVC.title = [self.localeToDisplay valueForKey:FLICKR_DICT_KEY_CITY];
        destVC.localeToDisplay = self.localeToDisplay;
        destVC.currentlyShowingMap = self.currentlyShowingMap;
    }
}

#pragma mark - Logic for embedded UIViewControllers

// Getters for the sub view controllers
- (TopPlacesMapViewController *)mapViewController
{
    if (_mapViewController == nil) {
        _mapViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TopPlacesMapViewControllerID"];
    }
    return _mapViewController;
}

- (TopPlacesTableViewController *)tableViewController
{
    if (_tableViewController == nil) {
        _tableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TopPlacesTableViewControllerID"];
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
        self.mapViewController.placesForMaps = [self placesForMaps];
        self.localeToDisplay = self.tableViewController.localeToDisplay;
        self.mapViewController.localeToDisplay = self.localeToDisplay;
        self.mapViewController.delegate = self;
        self.currentlyShowingMap = YES;
    } else if ([vc isEqual:self.tableViewController]) {
        self.tableViewController.places = [self places];
        self.localeToDisplay = self.mapViewController.localeToDisplay;
        self.tableViewController.localeToDisplay = self.localeToDisplay;
        self.tableViewController.delegate = self;
        self.currentlyShowingMap = NO;
    }
    
    [self addChildViewController:vc];
    [self transitionFromViewController:self.currentViewController
                      toViewController:vc
                              duration:0
                               options:UIViewAnimationOptionCurveLinear
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
    [self addChildViewController:self.tableViewController];
    self.tableViewController.delegate = self;
    self.tableViewController.view.frame = self.contentView.bounds;
    [self.contentView addSubview:self.tableViewController.view];
    self.currentViewController = self.tableViewController;
    self.currentlyShowingMap = NO;
    self.title = @"Top Places";  // I think I need this because there is no visible title, and this is used for back button!
    [self refresh:self.refreshButton];
}

- (void)viewDidUnload
{
    [self setRefreshButton:nil];
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