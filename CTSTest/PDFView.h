//
//  PDFView.h
//  demo_form_field
//
//  Created by Foxit on 12-2-7.
//  Copyright 2012 Foxit Software Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "fs_base.h"
#import "fpdf_base.h"
#import "fpdf_view.h"
#import "fpdf_annot.h"
#import "fpdf_document.h"
#import "fpdf_text.h"

@class PDFDocument;

@protocol TransferViewtestDelegate <NSObject>

@required
- (void)showDocument:(id)object;
@end

@interface PDFView : UIView {
    CGPoint startLocation;
	CGPoint endLocation;
    CGPoint currentPoint;
    CGPoint previousPoint;
	PDFDocument* m_pDocument;
	//PDF page handle.
	FPDF_PAGE m_curPage;
	//The current page index.
    int m_pageIndex;
	
	//The width of display area.
	int m_nSizeX;
	//The Height of display area.
	int m_nSizeY;
	//The horizontal position at which page start to render.
	int m_nStartX;
	//The vertical position at which page start to render.
	int m_nStartY;
    //The Size of Phone Displaying View Area
    CGSize m_mainsize;
    //The Pos of Image Displayed To the Phone View Area
    CGRect m_viewRect;
    NSInteger annotationSignWidth;
    NSInteger annotationSignHeight;
    FS_FLOAT m_zoomLevel;
    
    FS_FLOAT m_pageWidth;
    FS_FLOAT m_pageHeight;
    
}
@property(nonatomic,unsafe_unretained,readwrite) id <TransferViewtestDelegate> delegate;
@property (nonatomic, readwrite) BOOL btnNote;
@property (nonatomic, readwrite) BOOL btnHighlight;
@property (nonatomic, readwrite) BOOL btnErase;
@property (nonatomic, readwrite) BOOL btnSign;
@property (nonatomic, readwrite) BOOL FreeSignAll;
@property (nonatomic, readwrite) int DocumentPagesNb;
@property (nonatomic, strong) NSString* annotationNoteMsg;
@property (nonatomic, assign) NSInteger annotationSignWidth;
@property (nonatomic, assign) NSInteger annotationSignHeight;
@property (nonatomic, readwrite) CGPoint startLocation;
@property (nonatomic, readwrite) CGPoint endLocation;
@property (nonatomic,assign) PDFDocument *doc;
@property (nonatomic,readwrite) BOOL zooming;

- (void) OnPrevPage;
- (void) OnNextPage;
-(void) OnZoomIn;
-(int)GetPageIndex;
-(void) OnZoomOut;
- (void)initPDFDoc: (PDFDocument*)pdoc;
- (CGPoint)PageToDevicePoint:(FPDF_PAGE)page p1:(CGPoint)point;
- (CGPoint)DeviceToPagePoint:(FPDF_PAGE)page p1:(CGPoint)point;
@end
