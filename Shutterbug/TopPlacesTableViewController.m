//
//  TopPlacesTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/26/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "TopPlacesTableViewController.h"
#import "FlickrFetcher.h"
#import "Countries.h"
#import "FlickrPhotoTableViewController.h"

@interface TopPlacesTableViewController ()
@property (nonatomic, weak) NSDictionary *localeToDisplay;                  // What place do we want to show photos for
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;        // Need this for spinner reverting to refresh. See viewDidLoad
@end

@implementation TopPlacesTableViewController

@synthesize places = _places;
@synthesize localeToDisplay = _localeToDisplay;
@synthesize refreshButton = _refreshButton;

// This is called when you hit the refresh button. Also called 1st time you open
// up the top places panel on iPad or when launching on iPhone
- (IBAction)refresh:(id)sender {
    // Replace the button with a spinner. Made it white so as it will look good
    // in popovers

    UIActivityIndicatorViewStyle whichColor = UIActivityIndicatorViewStyleGray;
    
    // If we are on the iPad...
    if (self.splitViewController) {
        // and the iOS is < 5.1 (does not respond to presentsWityGesture) then we want a WHITE activity indicator
        // because the popOvers are black. Otherwise the grey is better
        if (![self.splitViewController respondsToSelector:@selector(presentsWithGesture)]) {
            whichColor = UIActivityIndicatorViewStyleWhite;
        }
    }
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:whichColor];
    
    [spinner startAnimating];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr places downloader", NULL);
    dispatch_async(downloadQueue, ^{

        // Get top places
        NSArray *places = [FlickrFetcher topPlaces];
        
        // Parse and sort places, still on another thread. This will return an array
        // of countries rather than of all the locations. Each country will have an
        // array of cities
        NSArray *finalizedPlaces = [TopPlacesTableViewController sortFlickrTopPlaces:places];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem = sender;
            self.places = finalizedPlaces;
        });
    });
    dispatch_release(downloadQueue);
}

// Bulk of work happens here after retrieving TopPlaces
+ (NSArray *)sortFlickrTopPlaces:(NSArray *)retrievedPlaces
{
    // If the call to the API failed and we got nothing back, do not try and sort it
    // and just return a blank list
    if (!retrievedPlaces) return nil;
    
    NSMutableArray *sortedPlacesList = [[NSMutableArray alloc] init];
    NSMutableArray *countryList = [[NSMutableArray alloc] init];
    
    // Trying to use blocks. Sadly this was not covered in
    // class although he was going to. Maybe next lecture? Still confused...
    // BUT got it to work...
    
    // This will execute this code on each element in the array
    [retrievedPlaces enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {

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
        
        [sortedPlacesList addObject:thisEntry];
    }];
    
    // Okay, so now we have a list of places, not sorted yet (despite name) that have entries for all the fields
    
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
            if (self.tableView.window) [self.tableView reloadData];
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
        FlickrPhotoTableViewController *destVC = segue.destinationViewController;
        destVC.title = [self.localeToDisplay valueForKey:FLICKR_DICT_KEY_CITY];
        destVC.topPlaceToSearch = self.localeToDisplay;
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

#pragma mark - UIViewController lifecycle

// Force a refresh. Trying to get data before the interface is even up...
// This is why I made th refreshButton an outles - since the code that gets called to refresh
// is usually from a button, and I replace the button with the spinner, I need to explicitly send
// it the button. By making it an outlet and declaring it I have access to it here.
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refresh:self.refreshButton];
}

- (void)viewDidUnload
{
    [self setRefreshButton:nil];
    [super viewDidUnload];
}

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


@end
