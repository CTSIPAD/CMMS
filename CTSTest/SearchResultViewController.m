//
//  SearchResultViewController.m
//  iBoard
//
//  Created by LBI on 11/14/13.
//  Copyright (c) 2013 LBI. All rights reserved.
//

#import "SearchResultViewController.h"
#import "ResultTableViewCell.h"
#import "ReaderDocument.h"
#import "ReaderViewController.h"
#import "CSearch.h"
#import "CParser.h"
#import "CCorrespondence.h"
#import "CAttachment.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"

@interface SearchResultViewController ()

@end

@implementation SearchResultViewController{
    AppDelegate *appDelegate ;
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
    CGFloat red = 29.0f / 255.0f;
    CGFloat green = 29.0f / 255.0f;
    CGFloat blue = 29.0f / 255.0f;
    self.tableView.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithRed:45.0f/255.0f green:45.0f/255.0f blue:45.0f/255.0f alpha:1.0];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"searchResultCell"];
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.searchResult=appDelegate.searchModule;
    
    }

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResult.correspondenceList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 125;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"searchResultCell";
    ResultTableViewCell *cell = [[ResultTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    CCorrespondence *correspondence=self.searchResult.correspondenceList[indexPath.row];
   
    CAttachment *attachment=correspondence.attachmentsList[0];
    for (id key in correspondence.systemProperties) {
        
        NSDictionary *subDictionary = [correspondence.systemProperties objectForKey:key];
        NSArray *keys=[subDictionary allKeys];
        NSDictionary *subSubDictionary = [subDictionary objectForKey:[keys objectAtIndex:0]];
        NSArray *subkeys=[subSubDictionary allKeys];
        NSString *value=[subSubDictionary objectForKey:[subkeys objectAtIndex:0]];
        if([[keys objectAtIndex:0] isEqualToString:@"Sender"])
        {
             if([appDelegate.userLanguage.lowercaseString isEqualToString:@"arabic"])
                 cell.label2.text=[NSString stringWithFormat:@"%@: %@",[[subSubDictionary allKeys] objectAtIndex:0],value];
                 else
            cell.label2.text=[NSString stringWithFormat:@"%@: %@",[[subSubDictionary allKeys] objectAtIndex:0],value];
        }else if([[keys objectAtIndex:0] isEqualToString:@"Subject"])
        {
            cell.label1.text=value;
        }else if([[keys objectAtIndex:0] isEqualToString:@"Reference"])
        {
             if([appDelegate.userLanguage.lowercaseString isEqualToString:@"arabic"])
                 cell.label3.text=[NSString stringWithFormat:@"%@: %@",[[subSubDictionary allKeys] objectAtIndex:0],value];
                 else
            cell.label3.text=[NSString stringWithFormat:@"%@: %@",[[subSubDictionary allKeys] objectAtIndex:0],value];
        }
        else if([[keys objectAtIndex:0] isEqualToString:@"Date"])
        {
             if([appDelegate.userLanguage.lowercaseString isEqualToString:@"arabic"])
                   cell.label4.text=[NSString stringWithFormat:@"%@: %@",[[subSubDictionary allKeys] objectAtIndex:0],value];
                 else
            cell.label4.text=[NSString stringWithFormat:@"%@: %@",[[subSubDictionary allKeys] objectAtIndex:0],value];
        }
    }
   
    [cell setImageThumbnailBase64:attachment.thumbnailBase64];
    
    [cell updateCell];
    if([appDelegate.userLanguage.lowercaseString isEqualToString:@"arabic"]){
        cell.label1.textAlignment=NSTextAlignmentRight;
        cell.label2.textAlignment=NSTextAlignmentRight;
        cell.label3.textAlignment=NSTextAlignmentRight;
        cell.label4.textAlignment=NSTextAlignmentRight;
        cell.imageView.frame=CGRectMake(self.view.frame.size.width-122, 3, 119, 119);
        cell.label1.frame=CGRectMake(10, 5, 600, 30);
        cell.label2.frame=CGRectMake(10, 40, 600, 25);
        cell.label3.frame=CGRectMake(10, 65, 600, 20);
        cell.label4.frame=CGRectMake(10, 85, 600, 20);

        
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSelectorOnMainThread:@selector(increaseProgress) withObject:@"" waitUntilDone:YES];
    [self performSelectorInBackground:@selector(openDocument:) withObject:[NSString stringWithFormat:@"%d",indexPath.row]];
    
}

-(void)openDocument:(NSString*)documentId{
    @try{
    CCorrespondence *correspondence=self.searchResult.correspondenceList[[documentId integerValue]];
    CAttachment *fileToOpen=correspondence.attachmentsList[0];
    
      NSString *tempPdfLocation=[fileToOpen saveInCacheinDirectory:correspondence.Id fromSharepoint:appDelegate.isSharepoint];
   
    // NSString *tempPdfLocation=[CParser loadPdfFile:fileToOpen.url inDirectory:correspondence.Id];
    if ([ReaderDocument isPDF:tempPdfLocation] == NO) // File must exist
    {
         [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"Warning")
                                                        message:NSLocalizedString(@"Alert.Extension",@"Document extension not supported.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    else{
    ReaderDocument *document=[self OpenPdfReader:tempPdfLocation];
    
    if (document != nil) // Must have a valid ReaderDocument object in order to proceed with things
    {
        ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithReaderDocument:document MenuId:100 CorrespondenceId:[documentId integerValue] AttachmentId:0];
        
        readerViewController.delegate = self; // Set the ReaderViewController delegate to self
        
  
        readerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        readerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:readerViewController animated:YES completion:^{
            [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
        }];

    }
    }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"SearchResultViewController" function:@"openDocument" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
    @finally {
       [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
    }
}

-(ReaderDocument*) OpenPdfReader:(NSString *) pdfPath{
    NSString *phrase = nil; // Document password (for unlocking most encrypted PDF files)
    
    NSString *filePath = pdfPath;// [pdfs lastObject];
    assert(filePath != nil); // Path to last PDF file
    
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:filePath password:phrase];
    
    return document;
}



- (void)dismissReaderViewController:(ReaderViewController *)viewController
{
    [self.navigationController popViewControllerAnimated:YES];
    
	     [viewController dismissViewControllerAnimated:YES completion:nil];
    AppDelegate *delegate=(AppDelegate*)[[UIApplication sharedApplication] delegate];
    
   // delegate.masterSelectedCell=@"Search";
    SearchResultViewController *searchResultViewController = [[SearchResultViewController alloc]initWithStyle:UITableViewStylePlain];
    UINavigationController *navController=[[UINavigationController alloc] init];
    [navController setNavigationBarHidden:YES animated:NO];
    [navController pushViewController:searchResultViewController animated:YES];
    
    
   
    
    NSArray *viewControllers=[[NSArray alloc] initWithObjects:[delegate.splitViewController.viewControllers objectAtIndex:0],navController,nil];
    delegate.splitViewController.delegate = (id)self;
    delegate.splitViewController.viewControllers = viewControllers;
}



/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (BOOL)splitViewController: (UISplitViewController*)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    if(UIInterfaceOrientationIsLandscape(orientation))
        return NO;
    else return YES;
}


- (void)increaseProgress{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Loading",@"Loading ...") maskType:SVProgressHUDMaskTypeBlack];
    
    
}
- (void)dismiss {
	[SVProgressHUD dismiss];
}

@end
