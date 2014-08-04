//
//  AcceptWithCommentViewController.h
//  CTSIpad
//
//  Created by DNA on 6/12/14.
//  Copyright (c) 2014 LBI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionTaskController.h"
#import "ReaderViewController.h"
#import "CAction.h"
@class AcceptWithCommentViewController;
@protocol ActionViewDelegate <NSObject>

@required // Delegate protocols
- (void)dismissReaderViewController:(ReaderViewController *)viewController;
-(void)ActionMoveHome:(AcceptWithCommentViewController*)viewcontroller;
-(void)AcceptReject:(NSString*)note viewController:(AcceptWithCommentViewController *)viewcontroller action:(CAction*)action;
-(void)SignAndSendIt:(NSString*)action document:(ReaderDocument *)document note:(NSString*)note;
-(void)send:(NSString*)action note:(NSString*)note;


@end

@interface AcceptWithCommentViewController : UIViewController<UITextViewDelegate,ActionTaskDelegate>
{
    CGRect originalFrame;
    BOOL isShown;
    UITextView *txtNote;
    
}
@property (nonatomic, unsafe_unretained, readwrite) id <ActionViewDelegate> delegate;
@property (nonatomic,retain) UITextView *txtNote ;
@property (nonatomic) BOOL isShown;
@property (nonatomic,retain) CAction* ActionName;
@property (nonatomic,retain) ReaderDocument* document;

- (id)initWithFrame:(CGRect)frame;
- (id)initWithActionName:(CGRect)frame Action:(CAction *)action;
-(void)show;
-(void)hide;
-(void)save;


@end
