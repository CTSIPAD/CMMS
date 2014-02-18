//
//  ActionsTableViewController.h
//  CTSTest
//
//  Created by DNA on 1/22/14.
//  Copyright (c) 2014 LBI. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CUser;

@interface ActionsTableViewController : UITableViewController

@property(nonatomic,strong)CUser *user;
@property(nonatomic,strong)NSString* correspondenceId;
@property(nonatomic,strong)NSString* docId;
@property(nonatomic,strong)NSMutableArray* actions;
@end
