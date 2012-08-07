//
//  TopPlacesTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "TopPlacesTableViewController.h"
#import "FlickrFetcher.h"
#import "Countries.h"

@interface TopPlacesTableViewController ()

@end

@implementation TopPlacesTableViewController
@synthesize places = _places;
@synthesize localeToDisplay = _localeToDisplay;


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
    [self.parentViewController performSegueWithIdentifier:@"Show Photos At Place" sender:self];
}

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
@end