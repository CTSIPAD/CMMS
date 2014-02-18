//
//  Signature.m
//  cfsPad
//
//  Created by EVER-ME EME on 7/31/12.
//
//

#import "Signature.h"
#import "Base64.h"
#import "CParser.h"
static
CGPoint midPoint(CGPoint p1 ,CGPoint p2){
    return CGPointMake((p1.x+p2.x)*0.5, (p1.y+p2.y)*0.5);
}
@implementation Signature
@synthesize sigView,signatureImage,userXmlData;
- (id)initWithFrame:(CGRect)frame signature:(NSString*) signature
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImageView* imageView=[[UIImageView alloc]initWithFrame:[self bounds]];
        imageView.userInteractionEnabled=YES;
        self.sigView=imageView;
        self.sigView.userInteractionEnabled=YES;
        
		self.backgroundColor=[UIColor clearColor];
		self.userInteractionEnabled=YES;
        
        if(![signature isEqualToString:@""]){
        [Base64 initialize];
         NSData* imgData;
         imgData=[Base64 decode:signature];
         UIImage *myImage=[UIImage imageWithData:imgData];
         [self.sigView setImage:myImage];
         [self setSignatureImage:myImage];
            
        }
        [self addSubview:sigView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch=[touches anyObject];
    previousPoint1=[touch previousLocationInView:self];
    previousPoint2=[touch previousLocationInView:self];
    currentPoint=[touch locationInView:self];
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    UITouch *touch=[touches anyObject];
    previousPoint2=previousPoint1;
    previousPoint1=[touch previousLocationInView:self];
    currentPoint=[touch locationInView:self];
    
    CGPoint mid1=midPoint(previousPoint1, previousPoint2);
    CGPoint mid2=midPoint(currentPoint, previousPoint1);
    
    UIGraphicsBeginImageContext(self.sigView.frame.size);
    CGContextRef context=UIGraphicsGetCurrentContext();
    
    [self.sigView.image drawInRect:CGRectMake(0, 0, self.sigView.frame.size.width, self.sigView.frame.size.height)];
    CGContextMoveToPoint(context, mid1.x, mid1.y);
    CGContextAddQuadCurveToPoint(context, previousPoint1.x, previousPoint1.y, mid2.x, mid2.y);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 2.0);

    CGContextSetRGBStrokeColor(context, 0, 18/255.0, 282/255.0, 1.0);
    CGContextStrokePath(context);
    self.sigView.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
}
-(void)clearImage{
    [UIView beginAnimations:nil context:nil];
    [UIView animateWithDuration:1 animations:nil];
    sigView.image = nil;
    [UIView commitAnimations];
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [self setSignatureImage:self.sigView.image];
}
@end
