//
//  AppDelegate.h
//  CTSTest
//
//  Created by DNA on 12/11/13.
//  Copyright (c) 2013 LBI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDFDocument.h"
@class CUser;
@class CSearch;
@class MainMenuViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic)UISplitViewController *splitViewController;
@property (strong, nonatomic) CUser *user;
@property (strong, nonatomic) CSearch *searchModule;
@property (nonatomic, strong) MainMenuViewController *masterView;
@property (assign, nonatomic) NSInteger selectedInbox;
@property (assign, nonatomic) NSInteger Inboxselected;
@property (assign, nonatomic)NSInteger inboxForArchiveSelected;
@property(nonatomic,assign)NSInteger menuSelectedItem;
@property (strong, nonatomic) NSString* userLanguage;
@property (strong, nonatomic) NSString* ipadLanguage;
@property(nonatomic,assign)BOOL isSharepoint;
@property(nonatomic,assign)BOOL isAnnotated;
@property(nonatomic,assign)BOOL isAnnotationSaved;

@property (strong,nonatomic)NSString* docUrl;

@property (strong,nonatomic)NSString* SiteId;
@property (strong,nonatomic)NSString* WebId;
@property (strong,nonatomic)NSString* FileId;
@property (strong,nonatomic)NSString* AttachmentId;
@property (strong,nonatomic)NSString* attachmentType;
@property (strong,nonatomic)NSString* FileUrl;

@property(nonatomic,assign)BOOL isSigned;

@property(nonatomic,assign)BOOL isBasketSelected;
@property (assign, nonatomic) NSInteger attachmentSelected;
@property (assign, nonatomic) NSInteger searchSelected;

@property (assign, nonatomic) PDFDocument *doc;
@property (assign,nonatomic) NSString* FolderName;
@property (strong,nonatomic) NSString* corresponenceId;
@property (strong,nonatomic) NSString* inboxId;
@property (strong,nonatomic) NSString* transferId;
@property (retain,nonatomic) NSMutableArray* folderNames;
@end
