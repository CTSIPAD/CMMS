//
//  PDFView.mm
//  demo_form_field
//
//  Created by Foxit on 12-2-7.
//  Copyright 2012 Foxit Software Corporation. All rights reserved.
//

#import "PDFView.h"
#import "PDFDocument.h"


@implementation PDFView{
    BOOL isZooming;
}
@synthesize  startLocation,endLocation,annotationSignHeight,annotationSignWidth;
- (void)initPDFDoc:(PDFDocument*) pdoc
{
	m_pDocument = pdoc;
    m_pageIndex = 0;
    m_zoomLevel = 100;
    m_curPage = [m_pDocument getPDFPage:m_pageIndex];
      FPDF_Page_GetSize(m_curPage, &m_pageWidth, &m_pageHeight);
     m_viewRect = [self bounds];
    // m_viewRect.size.height -= 50;
     m_mainsize = m_viewRect.size;
    
    m_nStartX = 0;
    m_nStartY = 0;
    m_nSizeX = m_mainsize.width;
    m_nSizeY = m_mainsize.height;
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
	CGPoint pt = [[touches anyObject] locationInView:self];
	
	//[[self superview] bringSubviewToFront:self];
	
	CGPoint startLoc = [self DeviceToPagePoint:m_curPage p1:pt];
	//form fill implemention.
   NSSet *allTouches = [event allTouches];
    if([allTouches count] > 0)
    {
        uint touchesCount = [allTouches count];
        
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
        uint touchesCount = [allTouches count];
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
        [m_pDocument AddStampAnnot:ptLeftTop secondPoint:ptRightBottom previousPoint:ptLeftTop];
        //[m_pdfDoc signDoc:ptLeftTop secondPoint:ptRightBottom ];
    }else if([self btnNote ])
    {
        //[m_pdfDoc AddNote:pt  note:[cView annotationNoteMsg]];
       	[m_pDocument AddNote:ptLeftTop secondPoint:ptRightBottom note:[self annotationNoteMsg]];
       
    }if([self btnHighlight])
    {
    }else{
        [m_pDocument extractText:ptLeftTop ];
    }
    
		
    [self setNeedsDisplay];

}
- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	
	// Retrieve the touch point
	CGPoint pt = [[touches anyObject] locationInView:self];
	
	//[[self superview] bringSubviewToFront:self];
	
	CGPoint startLoc = [self DeviceToPagePoint:m_curPage p1:pt];
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
    if(!isZooming){
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
    else{
    m_zoomLevel = m_nSizeX * 100 / m_pageWidth;
	
    if(m_viewRect.size.width <= m_mainsize.width)
        m_viewRect.origin.x = (m_mainsize.width - m_viewRect.size.width) / 2;
    if(m_viewRect.size.height <= m_mainsize.height)
        m_viewRect.origin.y = 0;
   
//    if(m_viewRect.size.width > m_mainsize.width)
//        m_viewRect.size.width = m_mainsize.width;
//    if(m_viewRect.size.height > m_mainsize.height)
//        m_viewRect.size.height = m_mainsize.height;
    
    int sizex = m_viewRect.size.width;
    int sizey = m_viewRect.size.height;
    FS_BITMAP dib = NULL;
	FS_Bitmap_Create(sizex, sizey, FS_DIBFORMAT_RGBA, NULL, 0, &dib);
    FPDF_RenderPage_SetHalftoneLimit(5000 * 5000);
    FPDF_RenderPage_Start(dib, m_curPage, -m_nStartX, -m_nStartY, m_nSizeX, m_nSizeY, 0, 0, NULL, NULL);
	
	int bmWidth = FS_Bitmap_GetWidth(dib);
	int bmHeight = FS_Bitmap_GetHeight(dib);
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, FS_Bitmap_GetBuffer(dib), FS_Bitmap_GetStride(dib)*bmHeight, NULL);
	CGImageRef image = CGImageCreate(bmWidth,bmHeight, 8, 32, FS_Bitmap_GetStride(dib), \
									 CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrderDefault, \
									 provider, NULL, YES, kCGRenderingIntentDefault);
	
	UIImage* uiImage = [UIImage imageWithCGImage:image];
    
    CGRect rct;
    rct.origin.x = 0;
    rct.origin.y = 0;
    rct.size = m_mainsize;
    [uiImage drawInRect:m_viewRect];
   
    CGDataProviderRelease(provider);
    CGImageRelease(image);
	FS_Bitmap_Destroy(dib);
    }

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
    isZooming=YES;
    if(m_zoomLevel > 200)
        return;
    m_nStartX = 0;
    m_nStartY = 0;
    
    m_nSizeX = m_pageWidth * (m_zoomLevel * 1.2) / 100;
    m_nSizeY = m_pageHeight * (m_zoomLevel * 1.2) / 100;
    m_viewRect.size.width = m_nSizeX;
    m_viewRect.size.height = m_nSizeY;
    int sizexOriginal = m_viewRect.size.width;
    int sizeyOriginal = m_viewRect.size.height;
    self.frame = CGRectMake((self.superview.frame.size.height-sizexOriginal)/2, 5, sizexOriginal,sizeyOriginal);
    m_viewRect.origin.x = 0;
    m_viewRect.origin.y = 0;
    CGRect rect = m_viewRect;
    rect.size = m_viewRect.size;
    [self setNeedsDisplay];
}
-(void) OnZoomOut
{
    isZooming=YES;
    if(m_zoomLevel < 100)
        return;
    m_nStartX = 0;
    m_nStartY = 0;
    
    m_nSizeX = m_pageWidth * (m_zoomLevel * 0.8) / 100;
    m_nSizeY = m_pageHeight * (m_zoomLevel * 0.8) / 100;
    m_viewRect.size.width = m_nSizeX;
    m_viewRect.size.height = m_nSizeY;
    int sizexOriginal = m_viewRect.size.width;
    int sizeyOriginal = m_viewRect.size.height;
    self.frame = CGRectMake((self.superview.frame.size.height-sizexOriginal)/2, 5, sizexOriginal,sizeyOriginal);
    m_viewRect.origin.x = 0;
    m_viewRect.origin.y = 0;
    CGRect rect = m_viewRect;
    rect.size = m_mainsize;
    [self setNeedsDisplay];
}


@end
