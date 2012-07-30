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
@property (nonatomic, weak) NSDictionary *photoToDisplay;
@property (nonatomic, weak) DetailViewController *detailViewController;
@end

@implementation PhotoTableViewController
@synthesize photos = _photos;

@synthesize photoToDisplay = _photoToDisplay;
@synthesize detailViewController = _detailViewController;
@synthesize spinner = _spinner;

- (void)setDetailViewController:(DetailViewController *)detailViewController
{
    if (_detailViewController != detailViewController) {
        _detailViewController = detailViewController;
    }
}

- (UIActivityIndicatorView *)spinner
{
    if (_spinner == nil) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _spinner;
    
}
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
    } else {
        cell.textLabel.text = photoTitle;
        cell.detailTextLabel.text = photoDescription;
    }
    
    return cell;
}


// Are we in a split view controller? If so, return detail view controller if it is a GraphViewController
- (DetailViewController *)splitViewDetailViewController
{
    // splitViews always have just two, detail is lastObject
    id gvc = [self.splitViewController.viewControllers lastObject];
    if (![gvc isKindOfClass:[DetailViewController class]]) gvc = nil;
    return gvc;
}

// For pressing update graph button from master of splitViewController
- (void)showPhoto
{
    if ([self splitViewDetailViewController]) {
        [[self splitViewDetailViewController] setPhotoDictionary:self.photoToDisplay];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"Show Photo"]) {
        DetailViewController *destVC = segue.destinationViewController;
        destVC.photoDictionary = self.photoToDisplay;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the current photo from the DB
    self.photoToDisplay = [self.photos objectAtIndex:indexPath.row];
    [self showPhoto];
}

@end
