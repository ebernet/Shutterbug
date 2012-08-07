//
//  FlickrTableViewController.m
//  Shutterbug
//
//  Created by Eytan Bernet on 8/6/12.
//  Copyright (c) 2012 Eytan Bernet. All rights reserved.
//

#import "FlickrTableViewController.h"
#import "FlickrViewController.h"
#import "FlickrFetcher.h"
#import "Countries.h"

@interface FlickrTableViewController ()

@end

@implementation FlickrTableViewController
@synthesize photos = _photos;
@synthesize localeToDisplay = _localeToDisplay;
@synthesize photoToDisplay = _photoToDisplay;


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.photos count];
}

// Set the name of the photo and/or description
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flickr Photo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    // Configure the cell...
    NSDictionary *photo = [self.photos objectAtIndex:indexPath.row];
    
    NSString *photoTitle = [photo objectForKey:FLICKR_PHOTO_TITLE];
    NSString *photoDescription = [photo valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
    
    if ([photoTitle isEqualToString:@""]) {
        cell.textLabel.text = ([photoDescription isEqualToString:@""])?@"Unknown":photoDescription;
        cell.detailTextLabel.text = @"";
    } else {
        cell.textLabel.text = photoTitle;
        cell.detailTextLabel.text = photoDescription;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block UIImage *image;
    __block UIImageView *currentImageViewPointer = cell.imageView;

    dispatch_queue_t downloadQueue = dispatch_queue_create("thumbnail downloader", NULL);
    dispatch_async(downloadQueue, ^{
        image = [self imageForCell:indexPath.row];
        dispatch_async(dispatch_get_main_queue(), ^{
        // If the left call out accessory at this point is the same as the one before we made the call,
        // then set the image on the main thread.
            if ([(UIImageView *)cell.imageView isEqual:currentImageViewPointer]) {
                [(UIImageView *)cell.imageView setImage:image];
            }
        });
    });
    dispatch_release(downloadQueue);
}

- (UIImage *)imageForCell:(NSInteger)row
{
    NSURL *url = [FlickrFetcher urlForPhoto:[self.photos objectAtIndex:row] format:FlickrPhotoFormatSquare];
    NSData *data = [NSData dataWithContentsOfURL:url];
    return data ? [UIImage imageWithData:data] : nil;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - Table view delegate

// We need to do this uniquely because we only want to add to recents when viewing images
// from the FlickrPhotoTableViewController, not from RecentPhotoTableViewController
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the current photo from the DB
    
    self.photoToDisplay = [self.photos objectAtIndex:indexPath.row];
    
    // Now do segue to bring up the a list of photos at the current location
    [(FlickrViewController *)self.parentViewController showPhoto];
//    [self.parentViewController performSegueWithIdentifier:@"Show Photo" sender:self];
}

// Just not upsidedown on iPhone
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (self.splitViewController)?YES:(interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
