//
//  DetailViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 7/25/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation DetailViewController

@synthesize imageView = _imageView;
@synthesize imageURL = _imageURL;

- (void)loadImage
{
    if (self.imageView) {
        if (self.imageURL) {

            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            
            UIBarButtonItem *backView = self.navigationItem.leftBarButtonItem;
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
            
            dispatch_queue_t imageDownloadQ = dispatch_queue_create("ShutterbugViewController image downloader", NULL);
            dispatch_async(imageDownloadQ, ^{
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.navigationItem.leftBarButtonItem = backView;
                    self.imageView.image = image;
                });
            });
            dispatch_release(imageDownloadQ);
        } else {
            self.imageView.image = nil;
        }
    }
}

- (void)setImageURL:(NSURL *)imageURL
{
    if (![_imageURL isEqual:imageURL]) {
        _imageURL = imageURL;
        if (self.imageView.window) {    // we're on screen, so update the image
            [self loadImage];
        } else {                        // we're not on screen, so no need to loadImage (it will happen next viewWillAppear:)
            self.imageView.image = nil; // but image has changed (so we can't leave imageView.image the same, so set to nil)
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.imageView.image && self.imageURL) [self loadImage];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload
{
    self.imageView = nil;
    [super viewDidUnload];
}

@end
