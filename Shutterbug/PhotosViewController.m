//
//  PhotosViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "PhotosViewController.h"
#import "FlickrFetcher.h"

@interface PhotosViewController ()
@end

@implementation PhotosViewController
@synthesize localeToDisplay = _localeToDisplay;

// Load photos to bring in photos from the TopPlacesToSearch dictionary.
- (void)loadTopPhotos {
    
    [self startSpinner];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSArray *photos = [FlickrFetcher photosInPlace:self.localeToDisplay maxResults:50];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self stopSpinner];
            
            self.photos = photos;
        });
    });
    dispatch_release(downloadQueue);
}

// Load up top photos from Flickr on a thread
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadTopPhotos];
}
@end