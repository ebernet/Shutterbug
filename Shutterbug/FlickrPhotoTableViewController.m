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
@property (nonatomic, weak) NSDictionary *photoToDisplay;
@property (nonatomic, weak) DetailViewController *detailViewController;
@end

@implementation FlickrPhotoTableViewController

@synthesize photos = _photos;
@synthesize photoToDisplay = _photoToDisplay;
@synthesize detailViewController = _detailViewController;

- (IBAction)refresh:(id)sender {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("flickr downloader", NULL);
    dispatch_async(downloadQueue, ^{
        NSArray *photos = [FlickrFetcher recentGeoreferencedPhotos];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.navigationItem.rightBarButtonItem = sender;
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

- (void)setDetailViewController:(DetailViewController *)detailViewController
{
    if (_detailViewController != detailViewController) {
        _detailViewController = detailViewController;
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.photos count];
}

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
    cell.textLabel.text = [photo objectForKey:FLICKR_PHOTO_TITLE];
    cell.detailTextLabel.text = [photo objectForKey:FLICKR_PHOTO_OWNER];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
 
    if ([segue.identifier isEqualToString:@"Show Photo"]) {
        DetailViewController *destVC = segue.destinationViewController;
        destVC.title = [self.photoToDisplay objectForKey:FLICKR_PHOTO_TITLE];
        destVC.imageURL = [FlickrFetcher urlForPhoto:self.photoToDisplay format:FlickrPhotoFormatLarge];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the current photo from the DB
    self.photoToDisplay = [self.photos objectAtIndex:indexPath.row];

    // Now do segue to bring up the photo viewer itself
    [self performSegueWithIdentifier:@"Show Photo" sender:self];
}

@end
