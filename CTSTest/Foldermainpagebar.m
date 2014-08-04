//
//  Foldermainpagebar.m
//  CMMSipad
//
//  Created by EVER-ME EME on 6/13/14.
//  Copyright (c) 2014 LBI. All rights reserved.
//

#import "Foldermainpagebar.h"

@implementation Foldermainpagebar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIButton *btnLogout=[[UIButton alloc]initWithFrame:CGRectMake(50, 50, 37, 37)];
        [btnLogout setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"Folder.png"]]forState:UIControlStateNormal];
        //[btnLogout addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnLogout];
    }
    return self;
}

-(void) hidefolders{
    self.hidden=true;
}
-(void) showfolders{
    self.hidden=false;
}

@end
