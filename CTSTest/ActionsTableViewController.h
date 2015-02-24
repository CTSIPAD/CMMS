//
//  ActionsTableViewController.h
//  CTSTest
//
//  Created by DNA on 1/22/14.
//  Copyright (c) 2014 LBI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionTaskController.h"
#import "ReaderDocument.h"
#import "CAction.h"
@class CUser;
@class ReaderMainToolbar;
@class ActionsTableViewController;
@class TransferViewController;

@protocol TransferViewDelegate <NSObject>

@required
-(void)movehome:(ActionsTableViewController*)viewcontroller;
-(void)PopUpCommentDialog:(UITableViewController*)viewcontroller Action:(CAction*)action;
-(void)send:(NSString*)action note:(NSString*)note;

@end


@interface ActionsTableViewController : UITableViewController<UIAlertViewDelegate>
{
    ReaderDocument *document;

}
@property(nonatomic,strong)CUser *user;
@property(nonatomic,strong)NSString* correspondenceId;
@property(nonatomic,strong)NSString* docId;
@property(nonatomic,strong)NSMutableArray* actions;
@property(nonatomic,strong)	ReaderDocument *document;
@property(nonatomic,unsafe_unretained,readwrite) id <TransferViewDelegate> delegate;

@end
