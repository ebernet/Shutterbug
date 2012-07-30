//
//  DetailViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "DetailViewController.h"
#import "FlickrPhotoTableViewController.h"
#import "FlickrFetcher.h"

@interface DetailViewController () <UIScrollViewDelegate, FlickrPhotoTableViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *toolbarTitle;
@property (strong, nonatomic) NSURL *imageURL;
@end

@implementation DetailViewController

@synthesize imageView = _imageView;
@synthesize spinner = _spinner;
@synthesize toolbar = _toolbar;
@synthesize toolbarTitle = _toolbarTitle;
@synthesize photoDictionary = _photoDictionary;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;

// This will be needed for iPad bar
- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
    if (_splitViewBarButtonItem != splitViewBarButtonItem) {
        NSMutableArray *toolBarItems = [self.toolbar.items mutableCopy];
        if (_splitViewBarButtonItem) [toolBarItems removeObject:_splitViewBarButtonItem];
        if (splitViewBarButtonItem) [toolBarItems insertObject:splitViewBarButtonItem atIndex:0];
        self.toolbar.items = toolBarItems;
        _splitViewBarButtonItem = splitViewBarButtonItem;
    }
}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)loadImage
{
    if (self.imageView) {
        if (self.imageURL) {

            [self.spinner startAnimating];
            
            dispatch_queue_t imageDownloadQ = dispatch_queue_create("ShutterbugViewController image downloader", NULL);
            dispatch_async(imageDownloadQ, ^{
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.imageURL]];
                // All image manipulation on main thread
                dispatch_async(dispatch_get_main_queue(), ^{

                    // We have the image, stop the animating
                    [self.spinner stopAnimating];
                    // And set the imageView to the image we loaded
                    self.imageView.image = image;

                    [self layoutImage];
                
                });
            });
            dispatch_release(imageDownloadQ);
        } else {
            self.imageView.image = nil;
        }
    }
}

- (void)setPhotoDictionary:(NSDictionary *)photoDictionary
{
    if (![_photoDictionary isEqual:photoDictionary]) {
        _photoDictionary = photoDictionary;
        if (self.imageView.window) {    // we're on screen, so update the image
            self.imageURL = [FlickrFetcher urlForPhoto:_photoDictionary format:FlickrPhotoFormatLarge];
            [self loadImage];
            if (self.splitViewController) {
                self.toolbarTitle.text = [_photoDictionary valueForKey:FLICKR_PHOTO_TITLE];
            } else {
                self.title = [_photoDictionary valueForKey:FLICKR_PHOTO_TITLE];
            }
        } else {                        // we're not on screen, so no need to loadImage (it will happen next viewWillAppear:)
            self.imageView.image = nil; // but image has changed (so we can't leave imageView.image the same, so set to nil)
            if (self.splitViewController) {
                self.toolbarTitle.text = @"Photo";
            } else {
                self.title = @"Photo";
            }
        }
    }
}

- (UIActivityIndicatorView *)spinner
{
    if (_spinner == nil) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _spinner;

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Photo"]) {
        [segue.destinationViewController setDelegate:self];
    }
}

- (void)FlickrPhotoTableViewController:(FlickrPhotoTableViewController *)sender chosePhoto:(id)photo{
    self.imageURL = photo;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)addToFavorites {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *recents = [[defaults objectForKey:RECENTS_KEY] mutableCopy];
    if (!recents) recents = [NSMutableArray array];
    // If there, move it to top
    if ([recents containsObject:self.photoDictionary]) {
        [recents removeObject:self.photoDictionary];
        [recents insertObject:self.photoDictionary atIndex:0];
    } else {
        // Okay, not already there, So we want to add it at the top, but if larger than 20, remove bottom...
        [recents insertObject:self.photoDictionary atIndex:0];
        if ([recents count] > 20) {
            [recents removeObject:[recents lastObject]];
        }
    }
    [defaults setObject:recents forKey:RECENTS_KEY];
    [defaults synchronize];
    NSLog(@"recents: %@",recents);
}


- (void)layoutImage
{
    if (self.imageView.image) {
        // Set the default zoom scale
        self.scrollView.zoomScale = 1;
        
        // And we want to be able to scroll to the full dimensions of the image. It may be
        //  SMALLER then the actual allowed width
        
        self.scrollView.contentSize = self.imageView.image.size;
        
        self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height);
        CGFloat xScale = (self.scrollView.bounds.size.width / self.imageView.image.size.width);
        CGFloat yScale = (self.scrollView.bounds.size.height / self.imageView.image.size.height);
        self.scrollView.zoomScale = (xScale < yScale)?yScale:xScale;  // Pick the larger size to zoom to
        [self addToFavorites];
    }
    
}

- (void)viewWillLayoutSubviews
{
    [self layoutImage];
}

- (void)viewDidUnload
{
    self.scrollView = nil;
    self.imageView = nil;
    [super viewDidUnload];
}


@end
