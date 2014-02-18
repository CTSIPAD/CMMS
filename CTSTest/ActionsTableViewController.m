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
#import "CParser.h"
#import "CFPendingAction.h"

@interface ActionsTableViewController ()

@end

@implementation ActionsTableViewController{
    AppDelegate *mainDelegate;
}

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
   
    labelTitle.text=actionProperty.label;
    
    NSData * data = [NSData dataWithBase64EncodedString:actionProperty.icon];
    
    UIImage *cellImage = [UIImage imageWithData:data];

    [imageView setImage:cellImage];
    if([mainDelegate.userLanguage.lowercaseString isEqualToString:@"arabic"]){
        labelTitle.textAlignment=NSTextAlignmentRight;
        imageView.frame=CGRectMake(cell.frame.size.width-45, 5, 37, 37);
    }
    [cell addSubview:imageView];
    [cell addSubview:labelTitle];
   
   
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    
     CAction *actionProperty=self.actions[indexPath.row];
    [self executeAction:actionProperty.action];
   
}

-(void)executeAction:(NSString*)action{
    
    @try{
    NSString* params=[NSString stringWithFormat:@"action=ExecuteCustomActions&token=%@&correspondenceId=%@&docId=%@&actionType=%@",self.user.token,self.correspondenceId,self.docId,action];
    NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
    NSString* url = [NSString stringWithFormat:@"http://%@?%@",serverUrl,params];
    NSURL *xmlUrl = [NSURL URLWithString:url];
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
    NSString *validationResultAction=[CParser ValidateWithData:xmlData];
    
    if(![validationResultAction isEqualToString:@"OK"])
    { if([validationResultAction isEqualToString:@"Cannot access to the server"])
    {
        CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:url];
        [mainDelegate.user addPendingAction:pa];
    }else
        [self ShowMessage:validationResultAction];
        
    }else [self ShowMessage:@"Action successfuly done."];
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ActionsTableViewController" function:@"executeAction" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
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
