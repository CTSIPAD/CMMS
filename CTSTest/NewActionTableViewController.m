//
//  NewActionTableViewController.m
//  CTSIpad
//
//  Created by DNA on 6/11/14.
//  Copyright (c) 2014 LBI. All rights reserved.
//

#import "NewActionTableViewController.h"
#import "ActionsTableViewController.h"
#import "CAction.h"
#import "CUser.h"
#import "CMenu.h"
#import "CParser.h"
#import "CFPendingAction.h"
#import "HomeViewController.h"
#import "MainMenuViewController.h"
#import "CSearch.h"
#import "ReaderMainToolbar.h"
#import "AppDelegate.h"
#import "AcceptWithCommentViewController.h"
@interface NewActionTableViewController ()
@end

@implementation NewActionTableViewController{
    
    AppDelegate *mainDelegate;
    AppDelegate *appDelegate;

}
@synthesize document,m_pdfview,doc;

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
    mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    CGFloat red = 29.0f / 255.0f;
    CGFloat green = 29.0f / 255.0f;
    CGFloat blue = 29.0f / 255.0f;
    self.tableView.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
    self.tableView.delegate=self;
    self.tableView.dataSource=self;
    [self.tableView setSeparatorColor:[UIColor whiteColor]];
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0,0,0,0)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"actionCell"];
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
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"nbofrows:%d",self.SignAction.count);
  return self.SignAction.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"actionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    UILabel *labelTitle= [[UILabel alloc] initWithFrame:CGRectMake(70, 5,cell.frame.size.width-140, 40)];
    labelTitle.textColor = [UIColor whiteColor];
    labelTitle.backgroundColor = [UIColor clearColor];
    
    CAction *actionProperty=self.SignAction[indexPath.row];
    
    labelTitle.text=actionProperty.label;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 37, 37)];
    UIImage *cellImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",actionProperty.action]];
    
   [imageView setImage:cellImage];
    if([mainDelegate.userLanguage.lowercaseString isEqualToString:@"ar"]){
        labelTitle.textAlignment=NSTextAlignmentRight;
       // imageView.frame=CGRectMake(cell.frame.size.width-45, 5, 37, 37);
    }
    [cell addSubview:imageView];
    [cell addSubview:labelTitle];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    [_delegate dismissPopUp:self];

   CAction *actionProperty=self.SignAction[indexPath.row];
    if([actionProperty.action isEqualToString:@"Sign"]||[actionProperty.action isEqualToString:@"SignAll"])
        [self ActionExecute:actionProperty.action document:document];
    else if([actionProperty.action isEqualToString:@"FreeSign"]||[actionProperty.action isEqualToString:@"FreeSignAll"]){
        [self SignWithLocation:actionProperty.action document:document];

    }
    else if([actionProperty.action isEqualToString:@"SignAndSend"]){
        [self SignAndSendIt:actionProperty document:document];
    }
}

-(void)SignAndSendIt:(CAction*)action document:(ReaderDocument *)document{
  
 
    [_delegate PopUpCommentDialogWhenSign:self Action:action document:self.document];
    

}

-(void)SignWithLocation:(NSString*)action document:(ReaderDocument *)document{
    m_pdfview.delegate = _delegate;
    [m_pdfview setDoc:self.doc];
    [m_pdfview setBtnHighlight:NO];
    [m_pdfview setBtnNote:NO];
    [m_pdfview setBtnSign:YES];
    if([action isEqualToString:@"FreeSignAll"]){
        [m_pdfview setFreeSignAll:YES];
        [m_pdfview setDocumentPagesNb:[self.document.pageCount intValue]];
    }else{
        [m_pdfview setFreeSignAll:NO];
        [m_pdfview setDocumentPagesNb:[m_pdfview GetPageIndex]+1];


    }
    UIAlertView *alertOk=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Info",@"Info") message:NSLocalizedString(@"Alert.Sign",@"Click on pdf document to sign") delegate:self cancelButtonTitle:NSLocalizedString(@"OK",@"OK") otherButtonTitles: nil];
    [alertOk show];


    

}
-(void)ActionExecute:(NSString*)action document:(ReaderDocument *)document{

            mainDelegate.isAnnotated=YES;
            mainDelegate.FileUrl = [mainDelegate.FileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
            int index;
    
            NSString *callMethod;
    
            if([action isEqualToString:@"Sign"]){
                index=[m_pdfview GetPageIndex]+1;
                callMethod = @"SignIt";

            }
            else if([action isEqualToString:@"SignAll"]){
                index=[self.document.pageCount intValue];
                callMethod = @"SignAll";

            }

    
    
            NSString* searchUrl = [NSString stringWithFormat:@"http://%@?action=%@&token=%d&correspondenceId=%d&transferId=%d&loginName=%@&pdfFilePath=%@&pageNumber=%d&SiteId=%@&FileId=%@&FileUrl=%@",serverUrl,callMethod,mainDelegate.user.token.intValue,mainDelegate.corresponenceId.intValue,mainDelegate.transferId.intValue,mainDelegate.user.loginName,mainDelegate.docUrl,index,mainDelegate.SiteId,mainDelegate.FileId,mainDelegate.FileUrl];
    
    
    
            NSURL *xmlUrl = [NSURL URLWithString:searchUrl];
            NSData *XmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
    
    
    
                CParser *p=[[CParser alloc] init];
                [p john:XmlData];
    
    
                [_delegate showDocument:nil];
    
    
    
                CGPoint ptLeftTop;
    
                ptLeftTop.x = 279;
                ptLeftTop.y = 360;
    
    
                [doc extractText:ptLeftTop];
    
                [m_pdfview setNeedsDisplay];
    
            NSString *validationResultAction=[CParser ValidateWithData:XmlData];
    
            if(![validationResultAction isEqualToString:@"OK"])
            {
                if([validationResultAction isEqualToString:@"Cannot access to the server"])
                {
                    CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:searchUrl];
                    [mainDelegate.user addPendingAction:pa];
                }else
                    
                    [self ShowMessage:validationResultAction];
                
            }else {
                
                [self ShowMessage:@"Action successfuly done."];
                
            }
            


    
}
-(void)ShowMessage:(NSString*)message{
    
    NSString *msg = message;
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Alert",@"Alert")
                          message: msg
                          delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
                          otherButtonTitles: nil];
    [alert show];
    
    
}
@end
