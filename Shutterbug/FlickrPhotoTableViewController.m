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
@end

@implementation FlickrPhotoTableViewController

@synthesize topPlaceToSearch = _topPlaceToSearch;

@synthesize photos = _photos;
@synthesize spinner = _spinner;

- (void)loadPhotos {

    [self.spinner startAnimating];
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSArray *photos = [FlickrFetcher photosInPlace:self.topPlaceToSearch maxResults:50];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            self.photos = photos;
        });
    });
    dispatch_release(downloadQueue);
}

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        if (self.tableView.window) [self.tableView reloadData];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadPhotos];
}

@end
