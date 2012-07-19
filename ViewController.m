//
//  ViewController.m
//  Nomad
//
//  Created by Roman Davidenko on 5/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@end

@implementation ViewController

@synthesize tableView;
@synthesize searchBar;
//@synthesize prList;
@synthesize detailViewController = _detailViewController;

NSMutableArray *list;
NSMutableArray *prList;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Pending Transactions";
    }
    return self;
}

- (void)dealloc
{
    [_detailViewController release];
    [super dealloc];
}

//—-insert individual row into the table view—-
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    //—-try to get a reusable cell—-
    UITableViewCell *cell = 
    [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:CellIdentifier]
                autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    //—-set the text to display for the cell—- 
    NSString *cellValue = [list objectAtIndex:indexPath.row];
    cell.textLabel.text = cellValue;
    
    //—-display an image—-
    //UIImage *image = [UIImage imageNamed:@"apple.jpeg"];
    //cell.imageView.image = image;
    
    
    return cell;
}

//—-set the number of rows in the table view—-
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [list count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"Pending Purchase Requisitions";
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil] autorelease];
	    }

        [self.navigationController pushViewController:self.detailViewController animated:YES];
    }
}

- (void)viewDidLoad
{
    //—-initialize the array—- 
    list = [[NSMutableArray alloc] init];
  
    NSString *postStr = [NSString stringWithFormat:@"page=1&rows=10&sidx=item_id&sord=asc"];
    NSString *queryURL = [NSString stringWithFormat:@"http://yaruss.xxxxx.discountasp.net/sb/PendingTransactions/GetAllPendingPRs"];
    
    NSLog(@"Query string %@", queryURL);
    
    NSURL *url = [NSURL URLWithString:queryURL];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[postStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    conn = [[NSURLConnection alloc] initWithRequest:req  delegate:self];
    if (conn) {
        webData = [[NSMutableData data] retain];
    }
    
    self.tableView.tableHeaderView = searchBar;
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeYes;

    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

-(void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *)response {
    [webData setLength:0];
}
-(void) connection:(NSURLConnection *) connection didReceiveData:(NSData *)data {
    [webData appendData:data];
}
-(void) connection:(NSURLConnection *) connection didFailWithError:(NSError *)error {
    [conn release];
    [webData release];
}

-(void) connectionDidFinishLoading:(NSURLConnection *) connection {
    [conn release];
    NSLog(@"DONE. Received bytes: %d", [webData length]);
    NSString *strResult = [[NSString alloc] initWithBytes:[webData mutableBytes] length:[webData length] encoding:NSUTF8StringEncoding];
    NSDictionary *result = [strResult JSONValue];
    NSDictionary *rows = [result objectForKey:@"Rows"];

    prList = [[NSMutableArray alloc] init];
    
    for (id theKey in rows) {
        NSDictionary *detailedItems = theKey;
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSString *dateEntry = nil;
        for (NSString *detailedKey in detailedItems) {
            NSString * detailedValue = [detailedItems objectForKey:detailedKey];
            
            [dict setObject:detailedValue forKey:detailedKey];
            
            NSLog(@"Key is %@, Value is %@", detailedKey, detailedValue);
            if ([detailedKey isEqual:(@"DateEntry")]) {
                dateEntry = detailedValue;
            }
            
            if ([detailedKey isEqual:(@"contract_id")]) {
                if (dateEntry != nil) {
                    [list addObject:[[[detailedValue stringByAppendingString:@" ("] stringByAppendingString:dateEntry] stringByAppendingString: @")"]];
                    dateEntry = nil;
                }
                else
                    [list addObject:detailedValue];
            }
        }
        
        [prList addObject:dict];
        [dict release];
        //NSLog(@"Count %d", [prList count]);
    }

    //NSLog(@"CountEnd %d", [prList count]);
    [strResult release];
    [webData release];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [list release];
    [prList release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
