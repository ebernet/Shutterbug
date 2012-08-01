//
//  FlickrPhotoTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "FlickrPhotoTableViewController.h"
#import "FlickrFetcher.h"

@interface FlickrPhotoTableViewController ()
@property (nonatomic, strong) NSDictionary *photoToDisplay;
@end

@implementation FlickrPhotoTableViewController

@synthesize topPlaceToSearch = _topPlaceToSearch;
@synthesize photoToDisplay = _photoToDisplay;

// Load photos to bring in photos from the TopPlacesToSearch dictionary.
- (void)loadTopPhotos {

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

// For recents, we load the settings from defaults. We can load them as the NIB is loading
// because we are not actually showing them just yet
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadTopPhotos];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Call the inherited...
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    // Unique to this class
    [self addToRecents];
}

@end
