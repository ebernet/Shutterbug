//
//  FlickrPhotoTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "FlickrPhotoTableViewController.h"
#import "FlickrFetcher.h"
#import "DetailViewController.h"

@interface FlickrPhotoTableViewController ()
@property (nonatomic, strong) NSDictionary *photoToDisplay;
@end

@implementation FlickrPhotoTableViewController

@synthesize topPlaceToSearch = _topPlaceToSearch;

@synthesize photoToDisplay = _photoToDisplay;
@synthesize photos = _photos;


// Load photos to bring in photos from the TopPlacesToSearch dictionary. Note we don't need
// to do a network fetch with the recents, we just load the array stored in defaults.
// See this difference in RecentPhotoTableViewController
- (void)loadPhotosFromDefaults {

    [self startSpinner];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSArray *photos = [FlickrFetcher photosInPlace:self.topPlaceToSearch maxResults:50];
        dispatch_async(dispatch_get_main_queue(), ^{

            [self stopSpinner];

            self.photos = photos;
        });
    });
    dispatch_release(downloadQueue);
}

// Need to do this uniquely for recents and for top places photos or else
// We don't get the update. Unsure why not.
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

// For recents, we load the settings from defaults. We can load them as the NIB is loading
// because we are not actually showing them just yet
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadPhotosFromDefaults];
}

#pragma mark - Table view delegate

// We need to do this uniquely because we only want to add to recents when viewing images
// from the FlickrPhotoTableViewController, not from RecentPhotoTableViewController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the current photo from the DB
    self.photoToDisplay = [self.photos objectAtIndex:indexPath.row];
    [self showPhoto];
    // Unique to this class
    [self addToRecents];
}

@end
