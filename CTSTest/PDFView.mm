//
//  PDFView.mm
//  demo_form_field
//
//  Created by Foxit on 12-2-7.
//  Copyright 2012 Foxit Software Corporation. All rights reserved.
//

#import "PDFView.h"
#import "PDFDocument.h"
#import "CUser.h"
#import "CParser.h"
#import "CFPendingAction.h"
@implementation PDFView{
    BOOL isZooming;
    AppDelegate *mainDelegate;
}
@synthesize  startLocation,endLocation,annotationSignHeight,annotationSignWidth,DocumentPagesNb,FreeSignAll,doc;
- (void)initPDFDoc:(PDFDocument*) pdoc
{
    //johnny annotation
	m_pDocument = pdoc;
    m_pageIndex = 0;
    m_zoomLevel = 100;
    
    m_curPage = [m_pDocument getPDFPage:m_pageIndex];
      FPDF_Page_GetSize(m_curPage, &m_pageWidth, &m_pageHeight);
     m_viewRect = [self bounds];
    // m_viewRect.size.height -= 50;
     m_mainsize = m_viewRect.size;

//    mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    
//    m_nStartX = 0;
//    m_nStartY = 0;
//    m_nSizeX = m_mainsize.width;
//    m_nSizeY = m_mainsize.height;
//    
//    
//    CGPoint ptLeftTop;
//    CGPoint ptRightBottom;
//    ptLeftTop.x=251;
//    ptLeftTop.y=602;
//    ptRightBottom.x=500;
//    ptRightBottom.y=102;
//
//        m_pageIndex=2;
//    
//    m_curPage = [m_pDocument getPDFPage:m_pageIndex];
//    [m_pDocument setCurPage:m_curPage];
//    
//    [m_pDocument AddNote:ptLeftTop secondPoint:ptLeftTop note:@"johnny & samer"];
//    
//    m_pageIndex=0;
//    
//    m_curPage = [m_pDocument getPDFPage:m_pageIndex];
//    [m_pDocument setCurPage:m_curPage];
//    
//    [m_pDocument AddHighlightAnnot:ptLeftTop secondPoint:ptRightBottom previousPoint:ptLeftTop];
//    
////    m_pageIndex=1;
////    
////    m_curPage = [m_pDocument getPDFPage:m_pageIndex];
////    [m_pDocument setCurPage:m_curPage];
////    
////    
////    ptLeftTop.x=151;
////    ptLeftTop.y=302;
////    ptRightBottom.x=200;
////    ptRightBottom.y=102;
////    [m_pDocument AddStampAnnot:ptLeftTop secondPoint:ptRightBottom previousPoint:ptLeftTop];
//
//    
//    m_pageIndex = 0;
//    
//    FPDF_Page_GetSize(m_curPage, &m_pageWidth, &m_pageHeight);
//    m_viewRect = [self bounds];
//    m_mainsize = m_viewRect.size;
}

- (CGPoint)PageToDevicePoint:(FPDF_PAGE)page p1:(CGPoint)point
{
	m_nStartX = 0;
	m_nStartY = 0;
	m_nSizeX = self.bounds.size.width;
	m_nSizeY = self.bounds.size.height;
	
	FS_POINT devPoint;
	FPDF_Page_PageToDevicePoint(m_curPage, m_nStartX, m_nStartY, m_nSizeX, m_nSizeY, 0, &devPoint);
	
	return CGPointMake(devPoint.x, devPoint.y);
}
- (CGPoint)DeviceToPagePoint:(FPDF_PAGE)page p1:(CGPoint)point
{
	m_nStartX = 0;
	m_nStartY = 0;
	m_nSizeX = self.bounds.size.width;
	m_nSizeY = self.bounds.size.height;
	
	FS_POINT pagePoint;
	pagePoint.x = point.x;
	pagePoint.y = point.y;
	FPDF_Page_DeviceToPagePoint(m_curPage, m_nStartX, m_nStartY, m_nSizeX, m_nSizeY, 0, &pagePoint);
	
	return CGPointMake(pagePoint.x, pagePoint.y);
}

- (id)initWithFrame:(CGRect)frame {
    m_curPage = NULL;
	m_pageIndex = -1;
    self = [super initWithFrame:frame];
    if (self) {
         m_mainsize = self.bounds.size;
    }
    return self;
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Unused variable CGPoint pt = [[touches anyObject] locationInView:self];
	
	//[[self superview] bringSubviewToFront:self];
	
//Unused variable CGPoint startLoc = [self DeviceToPagePoint:m_curPage p1:pt];
	//form fill implemention.
   NSSet *allTouches = [event allTouches];
    if([allTouches count] > 0)
    {
  //Unused Variable      uint touchesCount = [allTouches count];
        
        previousPoint=currentPoint;
        if (currentPoint.x!=0) {
          //  [m_pDocument setNewAnnotation:NO];
        }
        
        
        self.endLocation = [[touches anyObject] locationInView:self];
        currentPoint=self.endLocation;
        
        
        
    }
    
    //return;
	//move all points
    CGPoint ptLeftTop=[self DeviceToPagePoint:m_curPage p1:CGPointMake(startLocation.x, self.startLocation.y)];
    CGPoint ptRightBottom=[self DeviceToPagePoint:m_curPage p1:CGPointMake(endLocation.x, self.endLocation.y)];
    
    CGPoint ptPrev=[self DeviceToPagePoint:m_curPage p1:CGPointMake(previousPoint.x, previousPoint.y)];
  
   if([self btnHighlight]==YES)
        
        [m_pDocument AddHighlightAnnot:ptLeftTop secondPoint:ptRightBottom previousPoint:ptPrev];
        
    
	
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint pt = [[touches anyObject] locationInView:self];
	
	//[[self superview] bringSubviewToFront:self];
	
	CGPoint startLoc = [self DeviceToPagePoint:m_curPage p1:pt];
	//form fill implemention.
    
	NSSet *allTouches = [event allTouches];
    
    if([allTouches count] > 0)
    {
     //Unused variable   uint touchesCount = [allTouches count];
        self.endLocation = [[touches anyObject] locationInView:self];
        
    }
    
    //return;
	//move all points
    CGPoint ptLeftTop=[self DeviceToPagePoint:m_curPage p1:CGPointMake(startLocation.x, startLocation.y)];
    CGPoint ptRightBottom=[self DeviceToPagePoint:m_curPage p1:CGPointMake(endLocation.x, endLocation.y)];
    //   CGPoint devicePt= [cView PageToDevicePoint:m_curPage p1:pt];
    //CGPoint p2=CGPointMake(ptLeftTop.x+30,ptLeftTop.y- 30);
   
    if ([self btnErase]) {
        [m_pDocument eraseAnnotation:startLoc secondPoint:ptLeftTop];
    }else
    if ([self btnSign]) {
        //jis signmultiple
        self.btnSign=NO;
           // [m_pDocument AddStampAnnot:ptLeftTop secondPoint:ptRightBottom previousPoint:ptLeftTop];
        mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
        float xposition = startLoc.x;
        float yposition = startLoc.y;
        NSString* serverUrl1=[serverUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * callMethod;
        if(![self FreeSignAll])
            callMethod=@"FreeSignIt";
        else
            callMethod=@"FreeSignAll";
      
        
  NSString* signUrl = [NSString stringWithFormat:@"http://%@?action=%@&token=%d&correspondenceId=%d&transferId=%d&inboxId=%d&loginName=%@&pdfFilePath=%@&pageNumber=%d&SiteId=%@&FileId=%@&FileUrl=%@&positionX=%f&positionY=%f",serverUrl1,callMethod,mainDelegate.user.token.intValue,mainDelegate.corresponenceId.intValue,mainDelegate.transferId.intValue,mainDelegate.inboxId.intValue,mainDelegate.user.loginName,mainDelegate.docUrl,self.DocumentPagesNb,mainDelegate.SiteId,mainDelegate.FileId,[mainDelegate.FileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],xposition,yposition];

        
        
//        NSString* signUrl = [NSString stringWithFormat:@"http://%@?action=%@&positionX=%@&positionY=%@&loginName=%@&pdfFilePath=%@&pageNumber=%d&SiteId=%@&FileId=%@&FileUrl=%@",serverUrl1,callMethod,xposition,yposition,mainDelegate.user.loginName,mainDelegate.docUrl,self.DocumentPagesNb,mainDelegate.SiteId,mainDelegate.FileId,[mainDelegate.FileUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        
          NSString* strUrl = [signUrl stringByReplacingOccurrencesOfString:@"%5C" withString:@"\\"];
    
        NSURL *xmlUrl = [NSURL URLWithString:[strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSData *searchXmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];

        CParser *p=[[CParser alloc] init];
        [p john:searchXmlData];
        
        
        [_delegate showDocument:nil];
        
        
        
        CGPoint ptLeftTop;
        
        ptLeftTop.x = 279;
        ptLeftTop.y = 360;
        
        
        [self.doc extractText:ptLeftTop];
        
        [self setNeedsDisplay];
        
        
        NSString *validationResultAction=[CParser ValidateWithData:searchXmlData];
        
        if(![validationResultAction isEqualToString:@"OK"])
        {
            if([validationResultAction isEqualToString:@"Cannot access to the server"])
            {
                CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:serverUrl1];
                [mainDelegate.user addPendingAction:pa];
            }else
                
                [self ShowMessage:validationResultAction];
            
        }else {
            
            [self ShowMessage:@"Action successfuly done."];
            
        }

        
        
    }else if([self btnNote ])
    {
        self.btnErase=FALSE;
        //[m_pdfDoc AddNote:pt  note:[cView annotationNoteMsg]];
       	[m_pDocument AddNote:ptLeftTop secondPoint:ptRightBottom note:[self annotationNoteMsg]];
       
    }if([self btnHighlight])
    {
    }else
        if ([self btnNote]){
            self.btnNote =FALSE;
        }
        else{
            [m_pDocument extractText:ptLeftTop ];
        }
    
		
    [self setNeedsDisplay];

}
-(int)GetPageIndex{
    return m_pageIndex;
}
-(void)ShowMessage:(NSString*)message{
    
    NSString *msg = message;
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"Alert",@"Alert")
                          message: msg
                          delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
                          otherButtonTitles: nil];
    [alert show];
    
    
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	
	// Retrieve the touch point
	//Unused variable CGPoint pt = [[touches anyObject] locationInView:self];
	
	//[[self superview] bringSubviewToFront:self];
	
//Unused variable	CGPoint startLoc = [self DeviceToPagePoint:m_curPage p1:pt];
	//form fill implemention.
    
   self.startLocation = [[touches anyObject] locationInView:self];
	//[m_pdfDoc setNewAnnotation:YES];
    currentPoint.x=0;
    previousPoint.x=0;

	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	
	//Receive the input text,then set the text to the associated text field.
	
	NSString* pStringValue = [textField text];
	unichar* pBuff = new unichar[[pStringValue length]];
	NSRange range = {0, [pStringValue length]};
	[pStringValue getCharacters:pBuff range:range];
	//form fill implemention.
	
	[textField resignFirstResponder];
	[textField removeFromSuperview]; 
	return YES;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
	// Drawing code.
    if(isZooming){
        m_zoomLevel = m_nSizeX * 100 / m_pageWidth;
    }
    // if(!isZooming){
    CGContextRef myContext = UIGraphicsGetCurrentContext();
    
    CGRect cliprect = CGContextGetClipBoundingBox(myContext);
    m_nSizeX = self.bounds.size.width;
    m_nSizeY = self.bounds.size.height;
    
    int width, height;
    
    m_curPage = [m_pDocument getPDFPage:m_pageIndex];
    [m_pDocument setCurPage:m_curPage];
    
    m_nStartX = cliprect.origin.x;
    m_nStartY = cliprect.origin.y;
    width = cliprect.size.width;
    height = cliprect.size.height;
    
    FS_BITMAP dib = [m_pDocument getPageImageByRect:m_curPage p1:m_nStartX p2:m_nStartY
                                                 p3:m_nSizeX p4:m_nSizeY p5:width p6:height];
    
    int bmWidth = FS_Bitmap_GetWidth(dib);
    int bmHeight = FS_Bitmap_GetHeight(dib);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, FS_Bitmap_GetBuffer(dib), FS_Bitmap_GetStride(dib)*bmHeight, NULL);
    CGImageRef image = CGImageCreate(bmWidth,bmHeight, 8, 32, FS_Bitmap_GetStride(dib), \
                                     CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrderDefault, \
                                     provider, NULL, YES, kCGRenderingIntentDefault);
    
    UIImage* uiImage = [UIImage imageWithCGImage:image];
    
    [uiImage drawInRect:cliprect];
    
    
    CGDataProviderRelease(provider);
    CGImageRelease(image);
    FS_Bitmap_Destroy(dib);

    
}


- (void)dealloc {
    if(m_curPage)
        FPDF_Page_Close(m_curPage);
    
}

-(void) OnPrevPage
{
    isZooming=NO;
    m_pageIndex--;
    if(m_pageIndex < 0)
    {
        m_pageIndex++;
        return;
    }
    
    CGRect rect = m_viewRect;
    rect.origin.x = 0;
    rect.size.width = m_mainsize.width;
    [self setNeedsDisplayInRect:rect];
}

-(void) OnNextPage
{
    isZooming=NO;
    m_pageIndex++;
    int count = 0;
    FPDF_Doc_GetPageCount((FPDF_DOCUMENT)[m_pDocument getPDFDoc], &count);
    if(m_pageIndex > count - 1)
    {
        m_pageIndex--;
        return;
    }
    
    CGRect rect = m_viewRect;
    rect.origin.x = 0;
    rect.size.width = m_mainsize.width;
    [self setNeedsDisplayInRect:rect];
}

-(void) OnZoomIn
{
    _zooming=YES;
    isZooming=YES;
    if(m_zoomLevel > 200)
        return;
    m_nStartX = 0;
    m_nStartY = 0;
    
    m_nSizeX = m_pageWidth * (m_zoomLevel * 1.2) / 100;
    m_nSizeY = m_pageHeight * (m_zoomLevel * 1.2) / 100;
    //zoom jen
    if(m_nSizeY > 763){
        m_nSizeY=763;
    }
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        
        if(m_nSizeX > 1027 || m_nSizeY > 1452){
            m_nSizeX=1027;
            m_nSizeY=1452;
        }
    } else {
        
        if(m_nSizeX > 1027 || m_nSizeY > 1452){
            m_nSizeX=1027;
            m_nSizeY=1452;
        }
        
    }
    m_viewRect.size.width = m_nSizeX;
    m_viewRect.size.height = m_nSizeY;
    int sizexOriginal = m_viewRect.size.width;
    int sizeyOriginal = m_viewRect.size.height;
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        self.frame = CGRectMake(0, 0, sizexOriginal,sizeyOriginal);
    
    else
        self.frame = CGRectMake((self.superview.frame.size.height-sizexOriginal)/2, 5, sizexOriginal,sizeyOriginal);
    m_viewRect.origin.x = 0;
    m_viewRect.origin.y = 0;
    CGRect rect = m_viewRect;
    rect.size = m_viewRect.size;
    [self setNeedsDisplay];
}
-(void) OnZoomOut
{
    _zooming=YES;
    isZooming=YES;
    if(m_zoomLevel < 100)
        return;
    m_nStartX = 0;
    m_nStartY = 0;
    
    m_nSizeX = m_pageWidth * (m_zoomLevel * 0.8) / 100;
    m_nSizeY = m_pageHeight * (m_zoomLevel * 0.8) / 100;
    //zoom jen
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        //  m_nSizeX=768;
        //  m_nSizeY=1019;
        if(m_nSizeX < 768 || m_nSizeY < 1019){
            m_nSizeX=768;
            m_nSizeY=1019;
        }
    } else {
        if(m_nSizeX < 585 || m_nSizeY < 763){
            m_nSizeX=585;
            m_nSizeY=763;
        }
    }
    m_viewRect.size.width = m_nSizeX;
    m_viewRect.size.height = m_nSizeY;
    int sizexOriginal = m_viewRect.size.width;
    int sizeyOriginal = m_viewRect.size.height;
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
        self.frame = CGRectMake(0, 0, sizexOriginal,sizeyOriginal);
    else
        self.frame = CGRectMake((self.superview.frame.size.height-sizexOriginal)/2, 5, sizexOriginal,sizeyOriginal);
    m_viewRect.origin.x = 0;
    m_viewRect.origin.y = 0;
    CGRect rect = m_viewRect;
    rect.size = m_mainsize;
    [self setNeedsDisplay];
}

@end
