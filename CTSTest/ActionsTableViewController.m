//
//  ActionsTableViewController.m
//  CTSTest
//
//  Created by DNA on 1/22/14.
//  Copyright (c) 2014 LBI. All rights reserved.
//

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
@interface ActionsTableViewController ()

@end

@implementation ActionsTableViewController{
    AppDelegate *mainDelegate;
    AppDelegate *appDelegate;
}
@synthesize document;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
      self.clearsSelectionOnViewWillAppear = NO;
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
-(CGFloat)  tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.actions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"actionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 37, 37)];
    
    UILabel *labelTitle= [[UILabel alloc] initWithFrame:CGRectMake(70, 5,cell.frame.size.width-140, 40)];
    labelTitle.textColor = [UIColor whiteColor];
    labelTitle.backgroundColor = [UIColor clearColor];
    
    CAction *actionProperty=self.actions[indexPath.row];
    UIImage *cellImage;
    labelTitle.text=actionProperty.label;
    
        NSString* imagename=[NSString stringWithFormat:@"%@.png",actionProperty.label];
        cellImage =  [UIImage imageNamed:imagename] ;//[UIImage imageWithData:data];
    
    [imageView setImage:cellImage];
    if([mainDelegate.userLanguage.lowercaseString isEqualToString:@"ar"]){
        labelTitle.textAlignment=NSTextAlignmentRight;
        imageView.frame=CGRectMake(cell.frame.size.width-45, 5, 37, 37);
    }
    [cell addSubview:imageView];
    [cell addSubview:labelTitle];
   
   
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    
    CAction *actionProperty=self.actions[indexPath.row];
    if([actionProperty.action isEqualToString:@"Archive"]){
    [self executeAction:actionProperty.action];
        [_delegate movehome:self];
    }
    else
    if([actionProperty.action isEqualToString:@"SendFromPresident"]){
        [_delegate PopUpCommentDialog:self Action:actionProperty];
    }
    else if([actionProperty.action isEqualToString:@"SendToPresident"]){
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Send",@"Sending ...") maskType:SVProgressHUDMaskTypeBlack];

        [_delegate send:actionProperty.action note:@""];
        [_delegate movehome:self];
            [SVProgressHUD dismiss];
    }

    else{
        [_delegate PopUpCommentDialog:self Action:actionProperty];

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
-(void)executeAction:(NSString*)action{
    
    @try{
        
       
        
    NSString* params=[NSString stringWithFormat:@"action=ExecuteCustomActions&token=%@&correspondenceId=%@&docId=%@&actionType=%@", mainDelegate.user.token,self.correspondenceId,self.docId,action];
   NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
    NSString* url = [NSString stringWithFormat:@"http://%@?%@",serverUrl,params];
    NSURL *xmlUrl = [NSURL URLWithString:url];
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
    NSString *validationResultAction=[CParser ValidateWithData:xmlData];
    
    if(![validationResultAction isEqualToString:@"OK"])
    {
        if([validationResultAction isEqualToString:@"Cannot access to the server"])
        {
            CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:url];
            [mainDelegate.user addPendingAction:pa];
        }else
        
            [self ShowMessage:validationResultAction];
        
    }else {
        
        int nb;
        
        NSString *t=((CMenu*)mainDelegate.user.menu[mainDelegate.selectedInbox-1]).name;
        
        if([t isEqual:@"Meeting Agenda"]){
            nb=8;
        }
        else{
            if([t isEqual:@"Meeting Minutes"]){
                nb=14;
            }
            else{
                if([t isEqual:@"Tender Award Minutes"]){
                    nb=8;
                }
            }
        }
        
        NSString* correspondenceUrl = [NSString stringWithFormat:@"http://%@?action=GetCorrespondences&token=%@&inboxIds=%d",serverUrl,mainDelegate.user.token,nb];
        NSURL *xmlUrl = [NSURL URLWithString:correspondenceUrl];
        NSData *menuXmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
        
        NSMutableDictionary *correspondences=[CParser loadCorrespondencesWithData:menuXmlData];
        

        mainDelegate.searchModule.correspondenceList = [correspondences objectForKey:[NSString stringWithFormat:@"%d",nb]];
        
        [self ShowMessage:@"Action successfuly done."];
        
        

        
        
    }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ActionsTableViewController" function:@"executeAction" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
    
}



-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(buttonIndex==0){
        
        
        
//        UIViewController *localdetailViewController=nil;
//           UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
//           [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
//           [flowLayout setMinimumInteritemSpacing:5.0f];
//           [flowLayout setMinimumLineSpacing:5.0f];
//          HomeViewController *detail = [[HomeViewController alloc]initWithCollectionViewLayout:flowLayout];
//           localdetailViewController=detail;
//          UINavigationController *navController=[[UINavigationController alloc] init];
//          [navController setNavigationBarHidden:YES animated:NO];
//        [navController pushViewController:localdetailViewController animated:YES];
        //HomeViewController *home=[[HomeViewController alloc]init];
        //[self presentedViewController:home animated:YES completion:nil];
    }
}





@end
