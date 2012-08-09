//
//  DetailViewController.m
//  Shutterbug
//
//  This class handles the image panning and zooming and sixing and centering
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DetailViewController.h"
#import "SplitViewBarButtonItemPresenter.h"
#import "FlickrFetcher.h"
#import "FileOperations.h"

@interface DetailViewController () <UIScrollViewDelegate, UITabBarControllerDelegate, NSFileManagerDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *toolbarTitle;
@property (nonatomic) CGSize startingImageSize;
@property (strong, nonatomic) NSURL *imageURL;

@property (nonatomic, strong) NSURL *cacheDirectory;
@property (nonatomic) NSUInteger cacheSize;
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

@synthesize cacheDirectory = _cacheDirectory;
@synthesize cacheSize = _cacheSize;

#define MAX_CACHE_SIZE 10000000

#pragma mark - Image handeling

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

// Load the image on another thread
- (void)loadImage
{
    if (self.imageView) {
        if (self.imageURL) {
            
           
            [self.spinner startAnimating];
            dispatch_queue_t imageDownloadQ = dispatch_queue_create("ShutterbugViewController image downloader", NULL);
            dispatch_async(imageDownloadQ, ^{
                UIImage *image;
                
                // Pull off the file name for the name we will store
                NSURL *fileReference = [self.cacheDirectory URLByAppendingPathComponent:[[self imageURL] lastPathComponent]];

                // Do we have the file already stored in cache?
                if ([[NSFileManager defaultManager] fileExistsAtPath:[fileReference path]]) {
                    // YES, load from cache folder
                    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:fileReference]];
                } else {
                    // NO, load data and create image
                    NSData *imageData = [NSData dataWithContentsOfURL:self.imageURL];
                    image = [UIImage imageWithData:imageData];
                    
                    // Get the list of files in the cache, from newest to oldest
                    NSMutableArray *filesToDeleteFrom = [[FileOperations filesInReverseDateOrder:[[self cacheDirectory] path]] mutableCopy];

                    // Delete until we have room to add the new file
                    while (([imageData length] + self.cacheSize) > MAX_CACHE_SIZE) {
                        
                        // Get the URL for the oldest file in the cache
                        NSURL *lastFile = [self.cacheDirectory URLByAppendingPathComponent:[filesToDeleteFrom lastObject]];
                        
                        // Get its size, and remove it from the cache size
                        NSDictionary *lastFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[lastFile path] error:nil];
                        self.cacheSize -= [lastFileAttributes fileSize];

                        // Delete the file. Notice we may want to use error checking...
                        [[NSFileManager defaultManager] removeItemAtURL:lastFile error:nil];
                        
                        // And remove it from the array of files
                        [filesToDeleteFrom removeLastObject];
                        NSLog(@"cacheSize: %u", self.cacheSize);

                    }
                    // We have enough space to write the file out, so do it!
                    [imageData writeToURL:fileReference atomically:NO];
                }
                
                
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
    // Set self as the delegate for the UITabBarController so as we can be notified when a different tab is selected
    ((UITabBarController *)self.myPopoverController.contentViewController).delegate = self;

}

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    if ([aViewController isKindOfClass:[UITabBarController class]]) {
        // Set the title based on which UITabBarController view is selected
        UINavigationController *currentlySelectedController = (UINavigationController *)[(UITabBarController *)aViewController selectedViewController];
        NSString *tabBarItemTitle;
        if (!currentlySelectedController) {
            tabBarItemTitle = [[[(UITabBarController *)aViewController viewControllers] objectAtIndex:0] title];
        } else {
            tabBarItemTitle = [[(UITabBarController *)aViewController selectedViewController] title];
        }
        barButtonItem.title = tabBarItemTitle;
    } else {
        barButtonItem.title = [aViewController title];
    }
    // tell detail view to put up
    [self splitViewBarButtonItemPresenter].splitViewBarButtonItem = barButtonItem;
    self.myPopoverController = nil;
}

#pragma mark - UITabBarControllerDelegate method

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)aViewController
{
    // Each time you choose a new tab, set the button title based on the selected tab
    [self splitViewBarButtonItemPresenter].splitViewBarButtonItem.title = aViewController.title;
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

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.splitViewController.delegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Added the ability to zoom back to initial scale with double tap with two fingers
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    doubleTap.numberOfTouchesRequired = 2;
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];
    
    // Stash the size for quicker manipulation, only query size ONCE, then just the size of the files we delete!
    self.cacheSize = [FileOperations folderSize:[self.cacheDirectory path]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadImage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Show the masterViewController on initial showing, but only on initial
    if (self.splitViewController) {
        if ([_splitViewBarButtonItem.target respondsToSelector:_splitViewBarButtonItem.action]) {
            // Unsure how else to initiate the splitViewController button action. Don't know what it is that calls out the
            // masterviewcontroller, so I am just performing the action assigned the button, and am stuck with this warning
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.splitViewBarButtonItem.target performSelector:self.splitViewBarButtonItem.action withObject:self.splitViewBarButtonItem];
#pragma clang diagnostic pop
        }
    }
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

#pragma mark - File operations

// Returns a subfolder in the cache directory called Shutterbug, creates and returns it if it is not there
// Did not put this in FileOperations helper class because I return a cache folder with my application name.
// Probably could have JUST returned the cache folder since each application has a unique one, but this
// allows you to have multiple cache folders for EACH application
- (NSURL *)cacheDirectory
{
    if (_cacheDirectory == nil) {
        
        // Get the caches directory
        NSURL *cacheDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                             inDomain:NSUserDomainMask
                                                    appropriateForURL:nil
                                                               create:NO
                                                                error:nil];
        
        // append folder name
        cacheDirectory = [cacheDirectory URLByAppendingPathComponent:@"Shutterbug"];
        
        // Will either create it or it exists already, in which case I don't care about the error returned
        [[NSFileManager defaultManager] createDirectoryAtURL:cacheDirectory withIntermediateDirectories:NO attributes:nil error:nil];

        _cacheDirectory = cacheDirectory;
    }
    return _cacheDirectory;
}
@end