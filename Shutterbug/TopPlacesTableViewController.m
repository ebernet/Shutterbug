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
@property (nonatomic, weak) NSDictionary *countryToDisplay;
@property (nonatomic, weak) FlickrPhotoTableViewController *photosToDisplay;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@end

@implementation TopPlacesTableViewController

@synthesize places = _places;
@synthesize countryToDisplay = _countryToDisplay;
@synthesize photosToDisplay = _photosToDisplay;
@synthesize refreshButton = _refreshButton;

- (IBAction)refresh:(id)sender {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr places downloader", NULL);
    dispatch_async(downloadQueue, ^{

        // Get top places
        NSArray *places = [FlickrFetcher topPlaces];
        
        // Parse and sort places, still on another thread
        
        NSArray *finalizedPlaces = [TopPlacesTableViewController parseAndSortFlickrPlaces:places];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem = sender;
            self.places = finalizedPlaces;
        });
    });
    dispatch_release(downloadQueue);
}


+ (NSArray *)parseAndSortFlickrPlaces:(NSArray *)retrievedPlaces
{
    NSMutableArray *listParsedAndSorted = [[NSMutableArray alloc] init];
    NSMutableArray *listCountryLists = [[NSMutableArray alloc] init];
    
    [retrievedPlaces enumerateObjectsUsingBlock:^(id element, NSUInteger idx, BOOL *stop) {

        NSMutableDictionary *thisEntry = [element mutableCopy];
        
        // split on comma, and start with unknown values for 3 fields
        [thisEntry setValue:@"Unknown" forKey:FLICKR_DICT_KEY_CITY];
        [thisEntry setValue:@"Unknown" forKey:FLICKR_DICT_KEY_STATE];
        [thisEntry setValue:@"Unknown" forKey:FLICKR_DICT_KEY_COUNTRY];
        
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
        
        [listParsedAndSorted addObject:thisEntry];
    }];
    
    // now sort by country, city, state (in that order)
    [listParsedAndSorted sortUsingComparator:^NSComparisonResult(id obj1, id obj2){
        NSComparisonResult result;
        assert([obj1 isKindOfClass:[NSDictionary class]]);
        NSDictionary *dict1 = obj1;
        assert([obj2 isKindOfClass:[NSDictionary class]]);
        NSDictionary *dict2 = obj2;
        
        result = [[dict1 valueForKey:FLICKR_DICT_KEY_COUNTRY] localizedCaseInsensitiveCompare:[dict2 valueForKey:FLICKR_DICT_KEY_COUNTRY]];
        if (result == NSOrderedSame) {
            result = [[dict1 valueForKey:FLICKR_DICT_KEY_CITY] localizedCaseInsensitiveCompare:[dict2 valueForKey:FLICKR_DICT_KEY_CITY]];
        }
        if (result == NSOrderedSame) {
            result = [[dict1 valueForKey:FLICKR_DICT_KEY_STATE] localizedCaseInsensitiveCompare:[dict2 valueForKey:FLICKR_DICT_KEY_STATE]];
        }
        
        return result;
    }];
    
    // split into list of countries (sections) that each has a list of cities
    __block NSString *priorCountry = nil; // figure out if new
    __block Countries *workingCountryList = [[Countries alloc] init];
    
    [listParsedAndSorted enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        assert([obj isKindOfClass:[NSDictionary class]]);
        NSDictionary *locationDict = obj;
        
        NSString *currentCountryName = [locationDict valueForKey:FLICKR_DICT_KEY_COUNTRY];
        
        if (priorCountry && [currentCountryName localizedCaseInsensitiveCompare:priorCountry] != NSOrderedSame) {
            [listCountryLists addObject:[workingCountryList copy]];
            workingCountryList = [[Countries alloc] init];
        }
        workingCountryList.country = currentCountryName;
        [workingCountryList.cities addObject:[locationDict copy]];
        priorCountry = currentCountryName;
    }];
    [listCountryLists addObject:[workingCountryList copy]];
    
    return listCountryLists;
}

- (void)setPlaces:(NSArray *)places
{
    if (_places != places) {
        _places = places;

        [self.tableView reloadData];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refresh:self.refreshButton];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

//- (void)viewDidAppear:(BOOL)animated
//{
//    [self viewDidAppear:animated];
//}

- (void)viewDidUnload
{
    [self setRefreshButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
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
    Countries *country = [self.places objectAtIndex:indexPath.section];
    NSArray *cities = country.cities;
    NSDictionary *cityState = [cities objectAtIndex:indexPath.row];
    cell.textLabel.text = [cityState valueForKey:FLICKR_DICT_KEY_CITY];
    cell.detailTextLabel.text = [cityState valueForKey:FLICKR_DICT_KEY_STATE];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.places objectAtIndex:section] country];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/




- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"Show Photos At Place"]) {
        FlickrPhotoTableViewController *destVC = segue.destinationViewController;
        destVC.title = [self.countryToDisplay valueForKey:FLICKR_DICT_KEY_CITY];
        destVC.topPlaceToSearch = self.countryToDisplay;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the current city from the DB
    Countries *country = [self.places objectAtIndex:indexPath.section];
    NSArray *cities = country.cities;
    NSDictionary *cityState = [cities objectAtIndex:indexPath.row];
    self.countryToDisplay = cityState;
    
    // Now do segue to bring up the photo viewer itself
    [self performSegueWithIdentifier:@"Show Photos At Place" sender:self];
}

@end
