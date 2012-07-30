//
//  DetailViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "DetailViewController.h"
#import "FlickrFetcher.h"

@interface DetailViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
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

// Needed for scrolling, this is the delegate method
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

// Load the image on another thread
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
        self.imageURL = [FlickrFetcher urlForPhoto:_photoDictionary format:FlickrPhotoFormatLarge];
        if (self.imageView.window) {    // we're on screen, so update the image
            [self loadImage];
        }
    }
}

// We can be gray here. Have to be white for popOvers in iOS 5, might as well be white for these
// indicators on iPad
- (UIActivityIndicatorView *)spinner
{
    if (_spinner == nil) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _spinner;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)layoutImage
{
    if (self.imageView.image) {
        // Set the default zoom scale
        self.scrollView.zoomScale = 1;
        
        // And we want to be able to scroll to the full dimensions of the image. It may be
        //  SMALLER then the actual allowed width
        
        self.scrollView.contentSize = self.imageView.image.size;

        // Need to make sure we get the right title
        NSString *photoTitle = [_photoDictionary objectForKey:FLICKR_PHOTO_TITLE];
        NSString *photoDescription = [_photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        
        if ([photoTitle isEqualToString:@""]) {
            photoTitle = ([photoDescription isEqualToString:@""])?@"Unknown":photoDescription;
        }
        
        if (self.splitViewController) {
            self.toolbarTitle.text = photoTitle;
        } else {
            self.title = photoTitle;
        }

        self.imageView.frame = CGRectMake(0, 0, self.imageView.image.size.width, self.imageView.image.size.height);
        CGFloat xScale = (self.scrollView.bounds.size.width / self.imageView.image.size.width);
        CGFloat yScale = (self.scrollView.bounds.size.height / self.imageView.image.size.height);
        self.scrollView.zoomScale = (xScale < yScale)?yScale:xScale;  // Pick the larger size to zoom to
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadImage];
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
