//
//  SearchResultTableViewCell.h
//  iBoard
//
//  Created by DNA on 11/14/13.
//  Copyright (c) 2013 LBI. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultTableViewCell : UITableViewCell{
    
    UIImageView *imageView;
    UILabel *label1;
    UILabel *label2;
    UILabel *label3;
    UILabel *label4;
<<<<<<< HEAD
    UILabel *commentLabel;
=======
>>>>>>> 90e4806140e46fd428f3ed69711529ac9fe91a8b
}

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label1;
@property (nonatomic, strong) UILabel *label2;
@property (nonatomic, strong) UILabel *label3;
@property (nonatomic, strong) UILabel *label4;
<<<<<<< HEAD
@property (nonatomic, strong) UILabel *commentLabel;
=======
>>>>>>> 90e4806140e46fd428f3ed69711529ac9fe91a8b
@property (nonatomic, strong) NSString *imageThumbnailBase64;

-(void)updateCell;
@end
