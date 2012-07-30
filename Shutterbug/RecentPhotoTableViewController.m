//
//  RecentPhotoTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/29/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "RecentPhotoTableViewController.h"
#import "FlickrFetcher.h"
#import "DetailViewController.h"

@interface RecentPhotoTableViewController ()
@property (nonatomic, strong) NSDictionary *photoToDisplay;
@end

@implementation RecentPhotoTableViewController
@synthesize photoToDisplay = _photoToDisplay;
@synthesize photos = _photos;


// Load in the defaults from the 
- (void)loadDefaults
{
    NSArray *defaultRecents = [[NSUserDefaults standardUserDefaults] objectForKey:RECENTS_KEY];
    if (defaultRecents) {
        [self setPhotos:defaultRecents];
    }
}

// Needed to do this uniquely - could not inherit for this?
- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        if (self.tableView.window) [self.tableView reloadData];
    }
}

// Have to do on viewDidAppear so as we reload the recents list when using the
// TabBarController. Otherwise we don't get the latest added picture when we switch back
// and forth. Does this have to do with weak/strong? How does the UITableViewController for the other
// TabBar View Controller stay in memory?
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadDefaults];
}

#pragma mark - Table view delegate

// Note I am NOT adding to recents!
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the current photo from the DB
    self.photoToDisplay = [self.photos objectAtIndex:indexPath.row];
    [self showPhoto];
}


@end
