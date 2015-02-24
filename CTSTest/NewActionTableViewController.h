//
//  NewActionTableViewController.h
//  CTSIpad
//
//  Created by DNA on 6/11/14.
//  Copyright (c) 2014 LBI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReaderDocument.h"
@class CUser;
@class ReaderMainToolbar;
@class NewActionTableViewController;
@class TransferViewController;
@class ActionsTableViewController;
@class PDFDocument;

@protocol TransferViewDelegate <NSObject>

@required
-(void)PopUpCommentDialog:(NewActionTableViewController*)viewcontroller;
-(void)dismissPopUp:(NewActionTableViewController*)viewcontroller;
-(void)SignAndMovehome:(NewActionTableViewController *)viewcontroller;
-(void)PopUpCommentDialogWhenSign:(NewActionTableViewController*)viewcontroller Action:(NSString*)action document:(ReaderDocument*)document;
-(void)send:(NSString*)action note:(NSString*)note;
- (void)showDocument:(id)object;
-(void)extractText:(CGPoint)pt1;
@end

@interface NewActionTableViewController : UITableViewController{
     ReaderDocument *document;
    PDFView* m_pdfview;

}
@property(nonatomic,strong)NSMutableArray* SignAction;
@property(nonatomic,strong)	ReaderDocument *document;
@property(nonatomic,strong)	PDFDocument *doc;
@property(nonatomic,unsafe_unretained,readwrite) id <TransferViewDelegate> delegate;
@property(nonatomic,strong)	PDFView* m_pdfview;

@end
