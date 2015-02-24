//
//  Signature.h
//  cfsPad
//
//  Created by EVER-ME EME on 7/31/12.
//
//

#import <UIKit/UIKit.h>


@interface Signature : UIView{
    CGPoint previousPoint1;
    CGPoint previousPoint2;
    CGPoint currentPoint;
    UIImageView *view1;
}
@property (nonatomic,retain)    UIImageView *sigView;
@property(nonatomic,retain) UIImage* signatureImage;

@property (nonatomic,strong)  NSData *userXmlData;

- (id)initWithFrame:(CGRect)frame signature:(NSString*) signature;
-(void)clearImage;
@end
