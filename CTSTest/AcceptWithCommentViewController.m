//
//  AcceptWithCommentViewController.m
//  CTSIpad
//
//  Created by DNA on 6/12/14.
//  Copyright (c) 2014 LBI. All rights reserved.
//

#import "AcceptWithCommentViewController.h"
#import "ActionTaskController.h"
#import "AppDelegate.h"
#import "CUser.h"
#import "PMCalendar.h"
#import "CRouteLabel.h"
#import "CDestination.h"

@interface AcceptWithCommentViewController ()

@end

@implementation AcceptWithCommentViewController{
    CGRect _realBounds;
    ActionTaskController* actionController;
    
    BOOL isDirectionDropDownOpened;
    BOOL isTransferToDropDownOpened;
    CRouteLabel* routeLabel;
}
@synthesize txtNote,isShown;
@synthesize ActionName;
@synthesize delegate;
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.superview.bounds = _realBounds;
}

- (void)viewDidLoad { _realBounds = self.view.bounds; [super viewDidLoad]; }
- (id)initWithActionName:(CGRect)frame Action:(CAction *)action {
    
        self.ActionName =action;
    self = [self initWithFrame:frame];

    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    if (self) {
        originalFrame = frame;
        // self.view.alpha = 1;
        self.view.layer.cornerRadius=5;
        self.view.clipsToBounds=YES;
        self.view.layer.borderWidth=1.0;
        self.view.layer.borderColor=[[UIColor grayColor]CGColor];
        self.view.backgroundColor= [UIColor colorWithRed:29/255.0f green:29/255.0f  blue:29/255.0f  alpha:1.0];
        UILabel *Titlelabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, frame.size.width-20, 20)];
        NSString * nameAct=[NSString stringWithFormat:@"%@.%@Correspondence",self.ActionName.label,self.ActionName.label];



        Titlelabel.text = NSLocalizedString(nameAct,@"");
        Titlelabel.textAlignment=NSTextAlignmentCenter;
        Titlelabel.backgroundColor = [UIColor clearColor];
        if([ActionName.action isEqualToString:@"SignAndSend"]){
            Titlelabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:17];
        }
        else{
            Titlelabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
        }
        
        Titlelabel.textColor=[UIColor whiteColor];
        
      
        
        UILabel *lblNote = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, frame.size.width-20, 20)];
        lblNote.text = NSLocalizedString(@"Accept.Note",@"Note");
        lblNote.textAlignment=NSTextAlignmentLeft;
        lblNote.backgroundColor = [UIColor clearColor];
        //lblNote.font = [UIFont fontWithName:@"Helvetica" size:16];
        
        if([ActionName.action isEqualToString:@"SignAndSend"]){
               lblNote.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
        }
        else{
               lblNote.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
        }
     
        lblNote.textColor=[UIColor whiteColor];
        
        txtNote = [[UITextView alloc] initWithFrame:CGRectMake(10, 55, frame.size.width-20, frame.size.height-150)];
        txtNote.font = [UIFont systemFontOfSize:15];
        txtNote.delegate = self;
        
        txtNote.autocorrectionType = UITextAutocorrectionTypeNo;
        txtNote.keyboardType = UIKeyboardTypeDefault;
        txtNote.returnKeyType = UIReturnKeyDone;
        
        
        NSInteger btnWidth=115;
        
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        closeButton.frame =CGRectMake(((frame.size.width-(2*btnWidth +50))/2)+btnWidth+50, 310, btnWidth, 35);
        
        if([ActionName.action isEqualToString:@"SignAndSend"]){
            closeButton.titleLabel.font=[UIFont fontWithName:@"Helvetica-Bold" size:14];
        }
        else{
            closeButton.titleLabel.font=[UIFont fontWithName:@"Helvetica-Bold" size:18];
        }

        [closeButton setTitle:NSLocalizedString(@"Cancel",@"Cancel") forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        
        UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        saveButton.frame = CGRectMake((frame.size.width-(2*btnWidth +50))/2, 310, btnWidth, 35);
        if([ActionName.action isEqualToString:@"SignAndSend"]){
             saveButton.titleLabel.font=[UIFont fontWithName:@"Helvetica-Bold" size:14];
        }
        else{
             saveButton.titleLabel.font=[UIFont fontWithName:@"Helvetica-Bold" size:18];
        }
       
        [saveButton setTitle:NSLocalizedString(self.ActionName.label,@"Save") forState:UIControlStateNormal];
        [saveButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
        [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if([mainDelegate.ipadLanguage.lowercaseString isEqualToString:@"ar"]){
            lblNote.textAlignment=NSTextAlignmentRight;
        }
        
        
        
        
        [self.view addSubview:Titlelabel];
        [self.view addSubview:lblNote];
        
        [self.view addSubview:txtNote];
        [self.view addSubview:saveButton];
        [self.view addSubview:closeButton];
        
        
        
    }
    return self;
}



- (void)show
{
    // NSLog(@"show");
    
    isShown = YES;
    self.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.view.alpha = 0;
    [UIView beginAnimations:@"showAlert" context:nil];
    [UIView setAnimationDelegate:self];
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 12, 1, 1, 1.0);
    self.view.transform = CGAffineTransformMakeScale(1.1, 1.1);
    self.view.alpha = 1;
    [UIView commitAnimations];
    
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        NSLog(@"cancel");
        [self hide];
        
        //cancel clicked ...do your action
    }
    else if (buttonIndex == 1)
    {
        NSLog(@"save");
        //[alertView textFieldAtIndex:0].text
        
    }
}
-(void)clear{
    txtNote.text=@"";
}
- (void)hide
{
  //  [delegate ActionMoveHome:self];//Use to move home

   [self dismissViewControllerAnimated:YES completion:nil];
   
}

- (BOOL)disablesAutomaticKeyboardDismissal { return NO; }

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
    }
    return YES;
}




-(void)save{
    
    [NSThread detachNewThreadSelector:@selector(increaseLoading) toTarget:self withObject:nil];
    if([ActionName.action isEqualToString:@"SignAndSend"]){
        [delegate SignAndSendIt:ActionName.action document:self.document note:self.txtNote.text];
    }
    if([ActionName.label isEqualToString:@"Send"]){
        [delegate send:self.ActionName.action note:self.txtNote.text];
    }
    else{
        [delegate AcceptReject:self.txtNote.text viewController:self action:self.ActionName] ;
        }
    [self dismissViewControllerAnimated:YES  completion:^{
        [delegate ActionMoveHome:self];
    }];

      [NSThread detachNewThreadSelector:@selector(dismiss) toTarget:self withObject:nil];

}

#pragma mark delegate methods

-(void)actionSelectedDirection:(CRouteLabel*)route{
    
    
    routeLabel=route;
    
    for (UIView *view in self.view.subviews)
    {
        if ([view isKindOfClass:[UITableView class]]){
            [view removeFromSuperview];
        }
        
    }
}
-(void)actionSelectedDestination:(CDestination *)destination{
    
    
    
    for (UIView *view in self.view.subviews)
    {
        if ([view isKindOfClass:[UITableView class]]){
            [view removeFromSuperview];
        }
        
    }
}

-(void)increaseLoading{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Loading", @"Loading...") maskType:SVProgressHUDMaskTypeBlack];
}
-(void)dismiss{
    [SVProgressHUD dismiss];
}
@end

