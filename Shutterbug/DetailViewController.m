//
//  DetailViewController.m
//  Shutterbug
//
//  This class handles the image panning and zooming and sixing and centering
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "DetailViewController.h"
#import "SplitViewBarButtonItemPresenter.h"
#import "FlickrFetcher.h"

@interface DetailViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *toolbarTitle;
@property (nonatomic) CGSize startingImageSize;
@property (strong, nonatomic) NSURL *imageURL;
@end

@implementation DetailViewController

@synthesize imageView = _imageView;
@synthesize spinner = _spinner;
@synthesize toolbar = _toolbar;
@synthesize toolbarTitle = _toolbarTitle;
@synthesize photo = _photo;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize imageURL = _imageURL;
@synthesize startingImageSize = _startingImageSize;
@synthesize myPopoverController = _myPopoverController;

#pragma mark - Setters and getters

// Gets all the information about the photo
- (void)setPhoto:(NSDictionary *)photo
{
    if (![_photo isEqual:photo]) {
        _photo = photo;
        self.imageURL = [FlickrFetcher urlForPhoto:_photo format:FlickrPhotoFormatLarge];
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

#pragma mark - Image handeling

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
                    // And set the imageView to the image we loaded,
                    self.imageView.image = image;
                    // and back up the initial dimensions
                    self.startingImageSize = image.size;
                    [self layoutImage];
                });
            });
            dispatch_release(imageDownloadQ);
        } else {
            self.imageView.image = nil;
        }
    }
}

// Recenter the view if it is smaller than the full scroll area
- (void)recenterView
{
    // If we end up making the full image fit with space around it, we want to inset
    // it properly so as it is centered within the scrollView
    
    // Get the width and height of the actual image based on scale
    CGFloat currentImageWidth = self.startingImageSize.width * self.scrollView.zoomScale;
    CGFloat currentImageHeight = self.startingImageSize.height * self.scrollView.zoomScale;
    
    // We need to inset it if it is too small for the screen
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    // Will it get padding on either side?
    if (self.scrollView.bounds.size.width > currentImageWidth)
    {
        edgeInset.left = (self.scrollView.bounds.size.width - currentImageWidth) / 2;
        edgeInset.right = -edgeInset.left;  // Right is inset in - values (so if we want to go in 5 on every side, 5 from left, -5 is added to right, etc.
    }
    
    // Will it get padding on the top and bottom?
    if ( self.scrollView.bounds.size.height > currentImageHeight )
    {
        edgeInset.top = (self.scrollView.bounds.size.height - currentImageHeight) / 2;
        edgeInset.bottom = -edgeInset.top; // Top is inset in - values (so if we want to go in 5 on every side, 5 from top, -5 is added to bottom, etc.
    }
    // Do the insetting
    self.scrollView.contentInset = edgeInset;
}

- (void)layoutImage
{
    if (self.imageView.image) {
        // NOTE! This is all with view mode set to top left!!!
        // It will not work with other view modes!
        
        // Set the default zoom scale to 1 so as we can't make it smaller once
        // we have the full image
        self.scrollView.zoomScale = 1;
        
        // 1st figure out the aspect ration - of image, and of scrollRect
        // Depending on which has the aspect ration that fills the screen, that is the one we want to scale to

        CGFloat scrollRectRatio = self.scrollView.bounds.size.width / self.scrollView.bounds.size.height;
        CGFloat imageRatio = self.startingImageSize.width / self.startingImageSize.height;
        
        CGFloat zoomingRatio;
        
        if (scrollRectRatio > imageRatio) {
            //Portrait image, so size to width and allow scrolling on top and bottom
            zoomingRatio = self.scrollView.bounds.size.width / self.startingImageSize.width;
            
            // Zoom to that rectangle, keeping the height at 1
            [self.scrollView zoomToRect:CGRectMake(0, 0, zoomingRatio, 1.0) animated:NO];
            
            // Set the minimum scale so as we can shrink it down to see the full image. Base it on the height
            self.scrollView.minimumZoomScale = self.scrollView.bounds.size.height / self.startingImageSize.height;
            
            // Now set the zoomScale to match that ratio
            self.scrollView.zoomScale = zoomingRatio;
            
            // And zoom the frame to match the alloted space
            self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, self.startingImageSize.height * zoomingRatio);
        } else {
            //Landscape image, so size to height and allow scrolling left and right
            zoomingRatio = self.scrollView.bounds.size.height / self.startingImageSize.height;

            // Zoom to that rectangle, keeping the width at 1
            [self.scrollView zoomToRect:CGRectMake(0, 0, 1.0, zoomingRatio) animated:NO];
            
            // Set the minimum scale so as we can shrink it down to see the full image. Base it on the width
            self.scrollView.minimumZoomScale = self.scrollView.bounds.size.width / self.startingImageSize.width;
            
            // Now set the zoomScale to match that ratio
            self.scrollView.zoomScale = zoomingRatio;
            
            // And zoom the frame to match the alloted space
            self.scrollView.contentSize = CGSizeMake(self.startingImageSize.width * zoomingRatio, self.scrollView.bounds.size.height);

        }
        // The maximum ratio can be set after, and we can do the same setting for both scales
        self.scrollView.maximumZoomScale = self.scrollView.minimumZoomScale*5;

        // Recenter the view - will not actually do anything on initial drawing, but subsequent
        // calls to layoutImage (called when rotating) will take care of buffering if scale changed
        [self recenterView];
        
        // Set the title appropriately
        NSString *photoTitle = [self.photo objectForKey:FLICKR_PHOTO_TITLE];
        NSString *photoDescription = [self.photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        
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

#pragma mark - UISplitViewControllerDelagate stuff

// Get the detail view, since it will be presenting the button. Only if it implements the button
- (id <SplitViewBarButtonItemPresenter>)splitViewBarButtonItemPresenter
{
    id detailVC = [self.splitViewController.viewControllers lastObject];
    if (![detailVC conformsToProtocol:@protocol(SplitViewBarButtonItemPresenter)]) {
        detailVC = nil;
    }
    return detailVC;
}

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

// Only want to display button in portrait
- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)splitViewController:(UISplitViewController *)svc
          popoverController:(UIPopoverController *)pc
  willPresentViewController:(UIViewController *)aViewController
{
    // We save this so as we can dismiss it when we select a picture
    self.myPopoverController = pc;
}

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = [aViewController title];
    // tell detail view to put up
    [self splitViewBarButtonItemPresenter].splitViewBarButtonItem = barButtonItem;
    self.myPopoverController = nil;
}


#pragma mark - UIScrollViewDelegate methods


// Needed for scrolling and zooming, this is the delegate method
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

// recenter everything after zooming
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
    //properly sets the scrolling bounds.
    scrollView.contentSize = CGSizeMake(self.startingImageSize.width *scale, self.startingImageSize.height *scale);
    [self recenterView];
}


#pragma mark - Gesture recognizers


// If we double tap with two fingers, reset to original layout
- (void)tap:(UITapGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) || (gesture.state == UIGestureRecognizerStateEnded)) {
        [self layoutImage];
    }
}


#pragma mark - View lifecycle


- (void)awakeFromNib
{
    [super awakeFromNib];
    self.splitViewController.delegate = self;
}

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Added the ability to zoom back to initial scale with double tap with two fingers
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    doubleTap.numberOfTouchesRequired = 2;
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadImage];
}

- (void)viewWillLayoutSubviews
{
    // Force a reset of the scaling for orientation switch
    [self layoutImage];
}

- (void)viewDidUnload
{
    self.scrollView = nil;
    self.imageView = nil;
    [super viewDidUnload];
}
@end
