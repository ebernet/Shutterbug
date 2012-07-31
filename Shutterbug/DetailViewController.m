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

// Needed for scrolling and zooming, this is the delegate method
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

        // Set the default zoom scale to 1 so as we can't make it smaller once
        // we have the full image
        self.scrollView.zoomScale = 1;
        
        // Figure out scaling on x and y
        CGFloat xScale = (self.scrollView.bounds.size.width / self.imageView.image.size.width);
        CGFloat yScale = (self.scrollView.bounds.size.height / self.imageView.image.size.height);

        // Decide which of the sides to scale to...
        // What we do is the LARGER side becomes a scale of 1,
        // the other side gets scaled by that side's scale

        NSLog(@"xScale: %g, yScale: %g", xScale, yScale);
        NSLog(@"height before: %g, width before: %g",self.imageView.image.size.height, self.imageView.image.size.width);
        
        NSLog(@"height after: %g, width after: %g",self.imageView.image.size.height * yScale, self.imageView.image.size.width *xScale);
        
        if (xScale > yScale) {
            [self.scrollView zoomToRect:CGRectMake(0, 0, 1.0, self.imageView.image.size.height * xScale) animated:NO];
            self.scrollView.contentSize = CGSizeMake(self.imageView.image.size.width *yScale, self.imageView.image.size.height * xScale);
        } else {
            [self.scrollView zoomToRect:CGRectMake(0, 0, self.imageView.image.size.width * yScale, 1.0) animated:NO];
           self.scrollView.contentSize = CGSizeMake(self.imageView.image.size.width * xScale, self.imageView.image.size.height * yScale);
        }

        // ARGGGGGGGGGGGGGG!!G!G!GG!G!G!G!G!G!GG

        // Set the title appropriately
        NSString *photoTitle = [_photoDictionary objectForKey:FLICKR_PHOTO_TITLE];
        NSString *photoDescription = [_photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        
        // If we don't have a title yet, set it from the descrtiption. Or unknown if there is no description
        if ([photoTitle isEqualToString:@""]) {
            photoTitle = ([photoDescription isEqualToString:@""])?@"Unknown":photoDescription;
        }
        
        // Set the appropriate laeble field for iPad/iPhone
        if (self.splitViewController) {
            self.toolbarTitle.text = photoTitle;
        } else {
            self.title = photoTitle;
        }
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
