//
//	ReaderViewController.m
//	Reader v2.6.0
//

#import "ReaderConstants.h"
#import "ReaderViewController.h"
#import "ThumbsViewController.h"
#import "ReaderMainToolbar.h"
#import "ReaderMainPagebar.h"
#import "ReaderContentView.h"
#import "ReaderThumbCache.h"
#import "ReaderThumbQueue.h"
#import <MessageUI/MessageUI.h>
#import "CGPDFDocument.h"
#import "NoteAlertView.h"
#import "MetadataViewController.h"
#import "TransferViewController.h"
#import "CMenu.h"
#import "CCorrespondence.h"
#import "CAttachment.h"
#import "CFolder.h"
#import "AppDelegate.h"
#import "CParser.h"
#import "PDFDocument.h"
#import "PDFView.h"
#import "Base64.h"
#import "NSData-AES.h"
#import "NotesViewController.h"
#import "CDestination.h"
#import "CRouteLabel.h"
#import "CFPendingAction.h"
#import "AnnotationsTableViewController.h"
#import "ActionsTableViewController.h"
#import "GDataXMLNode.h"
#import "CSearch.h"
#import "ManageSignatureViewController.h"
#import "HomeViewController.h"
#import "NewActionTableViewController.h"
#import "AcceptWithCommentViewController.h"
#import "CAction.h"
#import "note.h"
#import "HighlightClass.h"
//#import "SVProgressHUD.h"

@interface ReaderViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate,
ReaderMainToolbarDelegate, ReaderMainPagebarDelegate, ReaderContentViewDelegate, ThumbsViewControllerDelegate>
@end

@implementation ReaderViewController
{
	ReaderDocument *document;
    
    
    
	ReaderMainToolbar *mainToolbar;
    
	ReaderMainPagebar *mainPagebar;
    
	NSMutableDictionary *contentViews;
    
	UIPrintInteractionController *printInteraction;
    
	NSInteger currentPage;
    
	CGSize lastAppearSize;
    
	NSDate *lastHideTime;
    
	BOOL isVisible;
    
    float lastContentOffset;
    UIInterfaceOrientation gCurrentOrientation;
    
    CGPDFDocumentRef PDFdocument;
    UISearchBar *searchBar;
    UISearchDisplayController *searchBarVC;
    Boolean Searching;
    UIPopoverController *searchPopVC;
    UITableView *tblSearchResult;
    UIViewController *ObjVC;
    
    NSArray *selections;
	//Scanner *scanner;
    NSString *keyword;
    
    CGPDFPageRef PDFPageRef;
    CGPDFDocumentRef PDFDocRef;
    NSMutableArray *arrSearchPagesIndex;
    int i;
    BOOL OrientationLock;
    AppDelegate *mainDelegate;
    
    BOOL isNoteVisible;
    BOOL isMetadataVisible;
    UIView *metadataContainer;
    
    NSMutableArray *folderNamesArray;
    UIScrollView *PdfScroll;
}

#pragma mark Constants

#define PAGING_VIEWS 3

#define TOOLBAR_HEIGHT 115.0f
#define PAGEBAR_HEIGHT 220.0f

#define TAP_AREA_SIZE 48.0f

#define TAG_DEV 1
#define TAG_SIGN 2
#define TAG_SAVE 3

#pragma mark Properties

@synthesize delegate,keyword,selections,openButton,numberPages,folderPagebar;

#pragma mark Support methods

- (void)updateScrollViewContentSize
{
    
	}

- (void)updateScrollViewContentViews
{
	}

- (void)updateToolbarBookmarkIcon
{
	
}

- (void)showDocumentPage:(NSInteger)page
{
	if (page != currentPage) // Only if different
	{
		NSInteger minValue; NSInteger maxValue;
		NSInteger maxPage = [document.pageCount integerValue];
		NSInteger minPage = 1;
        
		if ((page < minPage) || (page > maxPage)) return;
        
		if (maxPage <= PAGING_VIEWS) // Few pages
		{
			minValue = minPage;
			maxValue = maxPage;
		}
		else // Handle more pages
		{
			minValue = (page - 1);
			maxValue = (page + 1);
            
			if (minValue < minPage)
            {minValue++; maxValue++;}
			else
				if (maxValue > maxPage)
                {minValue--; maxValue--;}
		}
        
		NSMutableIndexSet *newPageSet = [NSMutableIndexSet new];
        
		NSMutableDictionary *unusedViews = [contentViews mutableCopy];
        
		CGRect viewRect = CGRectZero; viewRect.size = PdfScroll.bounds.size;
        
		for (NSInteger number = minValue; number <= maxValue; number++)
		{
			NSNumber *key = [NSNumber numberWithInteger:number]; // # key
            
			ReaderContentView *contentView = [contentViews objectForKey:key];
            
			if (contentView == nil) // Create a brand new document content view
			{
                
                m_pdfview = [[PDFView alloc]initWithFrame:viewRect];
                [m_pdfdoc setPDFView:m_pdfview];
                [m_pdfdoc setCurPage:[m_pdfdoc getPDFPage:number]];
                [m_pdfview initPDFDoc:m_pdfdoc];
 				contentView.message = self; [newPageSet addIndex:number];
			}
			else // Reposition the existing content view
			{
				contentView.frame = viewRect; [contentView zoomReset];
                
				[unusedViews removeObjectForKey:key];
			}
            
			viewRect.origin.x += viewRect.size.width;
		}
        
		[unusedViews enumerateKeysAndObjectsUsingBlock: // Remove unused views
         ^(id key, id object, BOOL *stop)
         {
             [contentViews removeObjectForKey:key];
             
             ReaderContentView *contentView = object;
             
             [contentView removeFromSuperview];
         }
         ];
        
		unusedViews = nil; // Release unused views
        
		CGFloat viewWidthX1 = viewRect.size.width;
		CGFloat viewWidthX2 = (viewWidthX1 * 2.0f);
        
		CGPoint contentOffset = CGPointZero;
        
		if (maxPage >= PAGING_VIEWS)
		{
			if (page == maxPage)
				contentOffset.x = viewWidthX2;
			else
				if (page != minPage)
					contentOffset.x = viewWidthX1;
		}
		else
			if (page == (PAGING_VIEWS - 1))
				contentOffset.x = viewWidthX1;
        
//        		if (CGPointEqualToPoint(scroll.contentOffset, contentOffset) == false)
//        		{
//        			scroll.contentOffset = contentOffset; // Update content offset
//        		}
        
		if ([document.pageNumber integerValue] != page) // Only if different
		{
			document.pageNumber = [NSNumber numberWithInteger:page]; // Update page number
		}
        
		NSURL *fileURL = document.fileURL; NSString *phrase = document.password; NSString *guid = document.guid;
        
		if ([newPageSet containsIndex:page] == YES) // Preview visible page first
		{
			NSNumber *key = [NSNumber numberWithInteger:page]; // # key
            
			ReaderContentView *targetView = [contentViews objectForKey:key];
            
			[targetView showPageThumb:fileURL page:page password:phrase guid:guid];
            
			[newPageSet removeIndex:page]; // Remove visible page from set
		}
        
		[newPageSet enumerateIndexesWithOptions:NSEnumerationReverse usingBlock: // Show previews
         ^(NSUInteger number, BOOL *stop)
         {
             NSNumber *key = [NSNumber numberWithInteger:number]; // # key
             
             ReaderContentView *targetView = [contentViews objectForKey:key];
             
             [targetView showPageThumb:fileURL page:number password:phrase guid:guid];
         }
         ];
        
		newPageSet = nil; // Release new page set
        
		[mainPagebar updatePagebar]; // Update the pagebar display
        
		//[self updateToolbarBookmarkIcon]; // Update bookmark
        
		currentPage = page; // Track current page number
	}
}

- (void)showDocument:(id)object
{
    @try{
        // Set content size
        
        //[self showDocumentPage:[document.pageNumber integerValue]];
        
        document.lastOpen = [NSDate date]; // Update last opened date
        
        isVisible = YES; // iOS present modal bodge
        CCorrespondence *correspondence;
        if(self.menuId!=100){
            correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
        }else{
            correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        }
        NSMutableArray* thumbnailrarray = [[NSMutableArray alloc] init];
        
        
        if (correspondence.attachmentsList.count>0)
        {
            for(CAttachment* doc in correspondence.attachmentsList)
            {
                if([doc.FolderName isEqualToString:mainDelegate.FolderName]){
                    [thumbnailrarray addObject:doc];
                }
                
                
            }
        }
        //jis next
        
        CAttachment *fileToOpen;
        
        if([mainDelegate.attachmentType isEqualToString:@"nextprevioustype"]){
            fileToOpen=correspondence.attachmentsList[self.attachmentId];
        }
        else{
            fileToOpen=thumbnailrarray[self.attachmentId];
        }
        
        
        mainDelegate.attachmentType =@"";
        
        //CAttachment *fileToOpen;
        
        
        
        [mainToolbar updateTitleWithLocation:fileToOpen.location withName:fileToOpen.title];
        NSString *tempPdfLocation=[fileToOpen saveInCacheinDirectory:correspondence.Id fromSharepoint:mainDelegate.isSharepoint];
        //NSString *tempPdfLocation=[CParser loadPdfFile:fileToOpen.url inDirectory:correspondence.Id];
        
        const char* file = [tempPdfLocation UTF8String];
        
        m_pdfdoc = [[PDFDocument alloc] init];
        [m_pdfdoc initPDFSDK];
        if(![m_pdfdoc openPDFDocument: file]){
            [m_pdfview removeFromSuperview];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"Warning")
                                                            message:NSLocalizedString(@"Alert.Extension",@"Document extension not supported.")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
                                                  otherButtonTitles:nil, nil];
            [alert show];
            
            
        }
        else{
            if(![self.view.subviews containsObject:m_pdfview]){
                float factor;
                UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
                if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
                    factor=1;
                    m_pdfview = [[PDFView alloc]initWithFrame:CGRectMake((self.view.bounds.size.width-self.view.bounds.size.width/factor)/2, 5, self.view.bounds.size.width/factor, self.view.bounds.size.height-5)];
                    PdfScroll.frame=m_pdfview.frame;
                    
                    //jis orientation
                    if(isMetadataVisible){
                        [metadataContainer removeFromSuperview];
                        [self.view addSubview:metadataContainer];
                        m_pdfview.frame=CGRectMake (325, 0, self.view.bounds.size.width/1.75, self.view.bounds.size.height-5);
                        PdfScroll.frame=m_pdfview.frame;
                        
                        metadataContainer.frame=CGRectMake(0, 0, 320, 1019);
                        numberPages.frame = CGRectMake(360, 950, 80, 40);
                        openButton.frame = CGRectMake(m_pdfview.frame.size.width/2-100, 0, 200, 40);
                    }
                    //endjis orientation
                } else {
                    factor=1.75;
                    m_pdfview = [[PDFView alloc]initWithFrame:CGRectMake((self.view.bounds.size.width-self.view.bounds.size.width/factor)/2, 5, self.view.bounds.size.width/factor, self.view.bounds.size.height-5)];
                    PdfScroll.frame=m_pdfview.frame;
                    
                    if(isMetadataVisible){
                        m_pdfview.frame=CGRectMake(320+(self.view.bounds.size.width-(320+m_pdfview.frame.size.width))/2, 0, m_pdfview.frame.size.width, m_pdfview.frame.size.height);
                        PdfScroll.frame=m_pdfview.frame;
                        
                    }
                }
                
                
                
            	PdfScroll = [[UIScrollView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width-self.view.bounds.size.width/factor)/2, 5, self.view.bounds.size.width/factor, self.view.bounds.size.height-5)];
            	PdfScroll.backgroundColor = [UIColor blackColor];
                PdfScroll.contentInset = UIEdgeInsetsZero;
            	PdfScroll.delegate = self;
                
                [m_pdfdoc setPDFView:m_pdfview];
                [m_pdfview initPDFDoc:m_pdfdoc];
                
                [m_pdfview addSubview:numberPages];
                
                [m_pdfview addSubview:folderPagebar];
                
                PdfScroll.contentSize = m_pdfview.frame.size;
                [PdfScroll addSubview:m_pdfview];
                
                PdfScroll.minimumZoomScale = PdfScroll.frame.size.width / m_pdfview.frame.size.width;
                PdfScroll.maximumZoomScale = 4.0;
                [PdfScroll setZoomScale:PdfScroll.minimumZoomScale];
                [m_pdfview addSubview:openButton];
                
                [self.view addSubview: PdfScroll];
                
                
                
            }
            else{
                [m_pdfdoc setPDFView:m_pdfview];
                [m_pdfview initPDFDoc:m_pdfdoc];
            }
            
            [self.view bringSubviewToFront:numberPages];
            [self.view bringSubviewToFront:openButton];
            [self.view bringSubviewToFront:mainToolbar];
            [self.view bringSubviewToFront:mainPagebar];
            [self.view bringSubviewToFront:folderPagebar];
            [self updateScrollViewContentSize];
            [self centreView];
        }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"showDocument" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
}
- (void)centreView
{
    m_pdfview.frame = [self centeredFrameForScrollView:PdfScroll andUIView:m_pdfview];
}


- (CGRect)centeredFrameForScrollView:(UIScrollView *)scroll andUIView:(UIView *)rView {
	CGSize boundsSize = scroll.bounds.size;
    CGRect frameToCenter = rView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    }
    else {
        frameToCenter.origin.x = 0;
    }
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    }
    else {
        frameToCenter.origin.y = 0;
    }
    
	return frameToCenter;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    m_pdfview.frame = [self centeredFrameForScrollView:scrollView andUIView:m_pdfview];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return m_pdfview;
}

- (void)zoomReset
{
	if (PdfScroll.zoomScale > PdfScroll.minimumZoomScale)
	{
		PdfScroll.zoomScale = PdfScroll.minimumZoomScale;
	}
}
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    zoomRect.size.height = [m_pdfview frame].size.height / scale;
    zoomRect.size.width  = [m_pdfview frame].size.width  / scale;
    
    center = [m_pdfview convertPoint:center fromView:PdfScroll];
    
    zoomRect.origin.x    = center.x - ((zoomRect.size.width / 2.0));
    zoomRect.origin.y    = center.y - ((zoomRect.size.height / 2.0));
    
    return zoomRect;
}

- (void)handleDoubleTapFrom:(UITapGestureRecognizer *)recognizer {
    
    float newScale = [PdfScroll zoomScale] *2.0;
    
    if (PdfScroll.zoomScale > PdfScroll.minimumZoomScale)
    {
        [PdfScroll setZoomScale:PdfScroll.minimumZoomScale animated:YES];
    }
    else
    {
        CGRect zoomRect = [self zoomRectForScale:newScale
                                      withCenter:[recognizer locationInView:recognizer.view]];
        [PdfScroll zoomToRect:zoomRect animated:YES];
    }
}
#pragma mark UIViewController methods

- (id)initWithReaderDocument:(ReaderDocument *)object MenuId:(NSInteger)menuId CorrespondenceId:(NSInteger)correspondenceId AttachmentId:(NSInteger)attachmentId
{
	id reader = nil; // ReaderViewController object
    
	if ((object != nil) && ([object isKindOfClass:[ReaderDocument class]]))
	{   self.menuId=menuId;
        self.correspondenceId=correspondenceId;
        self.attachmentId=attachmentId;
        mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
		if ((self = [super initWithNibName:nil bundle:nil])) // Designated initializer
		{
			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            
			[notificationCenter addObserver:self selector:@selector(applicationWill:) name:UIApplicationWillTerminateNotification object:nil];
            
			[notificationCenter addObserver:self selector:@selector(applicationWill:) name:UIApplicationWillResignActiveNotification object:nil];
            
			[object updateProperties]; document = object; // Retain the supplied ReaderDocument object for our use
            
			[ReaderThumbCache touchThumbCacheWithGUID:object.guid]; // Touch the document thumb cache directory
            
			reader = self; // Return an initialized ReaderViewController object
		}
	}
    
	return reader;
}

-(void) openToolbar{
    [self.view bringSubviewToFront:mainToolbar];
    [mainToolbar showToolbar];
}

-(void)openPagebar:(id)sender{
    
    
    NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Loading",@"Loading ...") maskType:SVProgressHUDMaskTypeBlack];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        mainDelegate.FolderName =folderarray[[sender tag]];
        
        CCorrespondence *correspondence;
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        
        
        if(![mainDelegate.folderNames containsObject:mainDelegate.FolderName]){
            
            [folderNamesArray addObject:mainDelegate.FolderName];
            [mainDelegate.folderNames addObject:mainDelegate.FolderName];
            NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
            
            int docId = [correspondence.Id intValue];
            
            NSString* attachmentUrl = [NSString stringWithFormat:@"http://%@?action=GetFolderAttachments&token=%@&docId=%d&folderName=%@",serverUrl,mainDelegate.user.token,docId,mainDelegate.FolderName];
            
            NSString* urlTextEscaped = [attachmentUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSURL *xmlUrl = [NSURL URLWithString:urlTextEscaped];
            NSData *attachmentXmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
            
            
            
            
            NSError *error;
            GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:attachmentXmlData
                                                                   options:0 error:&error];
            
            NSArray *Attachments = [doc nodesForXPath:@"//Attachments" error:nil];
            
            GDataXMLElement *AttachmentsXML;
            if (Attachments.count > 0) {
                AttachmentsXML =  [Attachments objectAtIndex:0];
            }
            
            NSArray *attachmentXML = [AttachmentsXML elementsForName:@"Attachment"];
            
            NSString *urlattach;
            NSString *idattach;
            NSString *thumbnailurlattach;
            
            for(GDataXMLElement *attachment in attachmentXML)
            {
                NSArray *ids = [attachment elementsForName:@"AttachmentId"];
                if (ids.count > 0) {
                    GDataXMLElement *idEl = (GDataXMLElement *) [ids objectAtIndex:0];
                    idattach = idEl.stringValue;
                }
                
                NSArray *urls = [attachment elementsForName:@"url"];
                if (urls.count > 0) {
                    GDataXMLElement *urlEl = (GDataXMLElement *) [urls objectAtIndex:0];
                    urlattach = urlEl.stringValue;
                }
                
                NSArray *thumbnailurls = [attachment elementsForName:@"ThumbnailUrl"];
                if (thumbnailurls.count > 0) {
                    GDataXMLElement *thumbnailurlEl = (GDataXMLElement *) [thumbnailurls objectAtIndex:0];
                    thumbnailurlattach = thumbnailurlEl.stringValue;
                }
                
                for(CAttachment* doc in correspondence.attachmentsList)
                {
                    if([doc.AttachmentId isEqualToString: idattach]){
                        doc.ThubnailUrl = thumbnailurlattach;
                        doc.url = urlattach;
                    }
                }
            }
        }
        
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            CGSize size = [UIScreen mainScreen].bounds.size;
            size = CGSizeMake(size.height, size.width);
            CGRect viewRect = CGRectMake( 0,0,size.width, self.view.bounds.size.height);
            
            //CGRect viewRect = CGRectMake( m_pdfview.bounds.origin.x+218,0,size.width, self.view.bounds.size.height);
            
            CGRect pagebarRect = viewRect;
            
            pagebarRect.size.height = PAGEBAR_HEIGHT;
            pagebarRect.origin.y = (viewRect.size.height - PAGEBAR_HEIGHT);
            
            mainPagebar = [[ReaderMainPagebar alloc] initWithFrame:pagebarRect Document:document CorrespondenceId:self.correspondenceId MenuId:self.menuId AttachmentId:self.attachmentId]; // At bottom
            
            
            
            //jis folderpagebar
            UIButton *gobackFolder=[[UIButton alloc]initWithFrame:CGRectMake(2, -20, 50, 50)];
            [gobackFolder setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"GoBack.png"]]forState:UIControlStateNormal];
            [gobackFolder addTarget:self action:@selector(closePagebar) forControlEvents:UIControlEventTouchUpInside];
            [mainPagebar addSubview:gobackFolder];
            [mainPagebar bringSubviewToFront:gobackFolder];
            
            mainPagebar.delegate = self;
            //    CGRect shadowRect = mainPagebar.bounds; shadowRect.size.height = 10.0f; shadowRect.origin.y -= shadowRect.size.height;
            //
            //    ReaderPagebarShadow *shadowView = [[ReaderPagebarShadow alloc] initWithFrame:shadowRect];
            //
            //    [mainPagebar addSubview:shadowView];
            [self.view addSubview:mainPagebar];
            mainPagebar.hidden=false;
            
            // [mainPagebar showPagebar];
            folderPagebar.hidden=true;
            [SVProgressHUD dismiss];
        });
    });
    
}

-(void)closePagebar{
    self.attachmentId=0;
    [mainPagebar removeFromSuperview];
    mainPagebar.hidden=true;
    mainPagebar=nil;
    //[mainPagebar hidePagebar];
    folderPagebar.hidden = false;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    folderNamesArray = [[NSMutableArray alloc]init];
    mainDelegate.folderNames = [[NSMutableArray alloc]init];
    openButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [openButton setTitle:[NSString stringWithFormat:@"Click to see the Menu"] forState:UIControlStateNormal];
    [openButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    openButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [openButton setTintColor:[UIColor whiteColor]];
    [openButton setBackgroundImage:[UIImage imageNamed:@"clickformenu.jpg"] forState:UIControlStateNormal];
    [openButton addTarget:self action:@selector(openToolbar) forControlEvents:UIControlEventTouchUpInside];
    // [self.view addSubview:openButton];
    
    
	assert(document != nil); // Must have a valid ReaderDocument
    
	//self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    self.view.backgroundColor=[UIColor colorWithRed:29/255.0f green:29/255.0f  blue:29/255.0f  alpha:1.0];
	CGRect viewRect = self.view.bounds; // View controller's view bounds
    
    
	CGRect toolbarRect = viewRect;
	toolbarRect.size.height = TOOLBAR_HEIGHT;
    
	mainToolbar = [[ReaderMainToolbar alloc] initWithFrame:toolbarRect document:document CorrespondenceId:self.correspondenceId MenuId:self.menuId AttachmentId:self.attachmentId]; // At top
	mainToolbar.delegate = self;
    
    
    
    
	[self.view addSubview:mainToolbar];
    
    [mainToolbar hideToolbar];
    
    folderPagebar = [[UIView alloc]init];
    
    
    
    folderPagebar.frame = CGRectMake(0, 2*PAGEBAR_HEIGHT+104,585.8, PAGEBAR_HEIGHT);
    
    
    folderPagebar.autoresizesSubviews = YES;
    folderPagebar.userInteractionEnabled = YES;
    folderPagebar.contentMode = UIViewContentModeRedraw;
    folderPagebar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    folderPagebar.backgroundColor = [UIColor colorWithRed:3/255.0f green:3/255.0f  blue:3/255.0f  alpha:0.8];
    
    
    UIScrollView* scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, folderPagebar.bounds.size.width, folderPagebar.bounds.size.height)];
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.scrollEnabled = YES;
    scrollView.pagingEnabled = YES;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.showsHorizontalScrollIndicator = YES;
    
    
    mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    folderarray = [[NSMutableArray alloc] init];
    
    for(CMenu* inbox in mainDelegate.user.menu)
    {
        if (inbox.correspondenceList.count>0)
        {
            for(CCorrespondence* correspondence in inbox.correspondenceList)
            {
                if (correspondence.attachmentsList.count>0)
                {
                    for(CAttachment* doc in correspondence.attachmentsList)
                    {
                        if(![folderarray containsObject:doc.FolderName]){
                            
                            [folderarray addObject:doc.FolderName];
                            
                        }
                        
                    }
                }
            }
        }
    }
    
    scrollView.contentSize = CGSizeMake(folderPagebar.bounds.size.width * 3, folderPagebar.bounds.size.height);
    
    for( i=0 ;i<folderarray.count;i++){
        UIButton *btnFolder;
        UILabel* folderlabel;
        
        if(i%4==0){
            btnFolder=[[UIButton alloc]initWithFrame:CGRectMake(26+26+(140*i), 30, 100, 130)];
            
            folderlabel=[[UILabel alloc]initWithFrame:CGRectMake(26+26+(140*i), 100, 100, 100)];
        }
        else{
            btnFolder=[[UIButton alloc]initWithFrame:CGRectMake(26+(140*i), 30, 100, 130)];
            
            folderlabel=[[UILabel alloc]initWithFrame:CGRectMake(26+(140*i), 100, 100, 100)];
        }
        
        
        
        [btnFolder setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"Folder.png"]]forState:UIControlStateNormal];
        
        folderlabel.text=[folderarray objectAtIndex:i];
        
        folderlabel.lineBreakMode = NSLineBreakByWordWrapping;
        folderlabel.numberOfLines = 2;
        
        folderlabel.textAlignment=NSTextAlignmentCenter;
        folderlabel.backgroundColor = [UIColor clearColor];
        folderlabel.font = [UIFont fontWithName:@"Helvetica" size:17];
        folderlabel.textColor=[UIColor whiteColor];
        //  [btnFolder setTitle:[folderarray objectAtIndex:i] forState:UIControlStateNormal];
        btnFolder.tag =i;
        [btnFolder addTarget:self action:@selector(openPagebar:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:btnFolder];
        [scrollView addSubview:folderlabel];
        
    }
    [folderPagebar addSubview:scrollView];
    
    
    //    UIButton *btnFolder=[[UIButton alloc]initWithFrame:CGRectMake(folderPagebar.frame.size.width/2-50, 0, 70, 70)];
    //    [btnFolder setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"Folder.png"]]forState:UIControlStateNormal];
    //    [btnFolder addTarget:self action:@selector(openPagebar) forControlEvents:UIControlEventTouchUpInside];
    //    [folderPagebar addSubview:btnFolder];
    folderPagebar.hidden=true;
    
    CGRect shadowRect = folderPagebar.bounds; shadowRect.size.height = 10.0f; shadowRect.origin.y -= shadowRect.size.height;
    
    ReaderPagebarShadow *shadowView = [[ReaderPagebarShadow alloc] initWithFrame:shadowRect];
    
    [folderPagebar addSubview:shadowView];
    
    //end jis folderpagebar
    
    
    //mounir note
    //
    //	mainPagebar.delegate = self;
    //
    //	[self.view addSubview:mainPagebar];
    //
    //    [mainPagebar hidePagebar];
    
	UILongPressGestureRecognizer *singleTapOne = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	[self.view addGestureRecognizer:singleTapOne];
    
    
    
    UITapGestureRecognizer *doubleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapFrom:)];
    doubleTapOne.numberOfTouchesRequired = 1; doubleTapOne.numberOfTapsRequired = 2; doubleTapOne.delegate = self;
	[self.view addGestureRecognizer:doubleTapOne];
    UITapGestureRecognizer *doubleTapTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapFrom:)];
    doubleTapTwo.numberOfTouchesRequired = 2; doubleTapTwo.numberOfTapsRequired = 2; doubleTapTwo.delegate = self;
    [self.view addGestureRecognizer:doubleTapTwo];
    
    [singleTapOne requireGestureRecognizerToFail:doubleTapOne]; // Single tap requires double tap to fail
    
    
    UISwipeGestureRecognizer *swipeRecognizerLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    swipeRecognizerLeft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizerLeft];
    
    UISwipeGestureRecognizer *swipeLeftRecognizerRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    swipeLeftRecognizerRight.direction=UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeLeftRecognizerRight];
    
    //    UISwipeGestureRecognizer *swipeRecognizerUp=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    //    swipeRecognizerUp.direction=UISwipeGestureRecognizerDirectionUp;
    //    [self.view addGestureRecognizer:swipeRecognizerUp];
    //
    //    UISwipeGestureRecognizer *swipeRecognizerDown=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    //    swipeRecognizerDown.direction=UISwipeGestureRecognizerDirectionDown;
    //    [self.view addGestureRecognizer:swipeRecognizerDown];
    
    
	contentViews = [NSMutableDictionary new]; lastHideTime = [NSDate date];
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    
    
    
    
    numberPages = [UIButton buttonWithType:UIButtonTypeCustom];
    
    
    
    numberPages.frame = CGRectMake(self.view.frame.size.width-263, 720, 80, 30);
    currentPage++;
    [numberPages setTitle:[NSString stringWithFormat:@"%d of %@",currentPage,document.pageCount] forState:UIControlStateNormal];
    
    [numberPages setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    numberPages.titleLabel.font = [UIFont systemFontOfSize:12];
    [numberPages setTintColor:[UIColor whiteColor]];
    numberPages.backgroundColor = [UIColor blackColor];
    
    
    CCorrespondence *correspondence;
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }
    
    mainDelegate.inboxId = correspondence.inboxId;
    
    [self adjustButtons:orientation];
}




-(void)adjustButtons:(UIInterfaceOrientation)orientation{
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        
        openButton.frame = CGRectMake(self.view.bounds.size.width/2-100, 0, 200, 40);
        numberPages.frame = CGRectMake(687.8, 950, 80, 40);
    } else {
        
        openButton.frame = CGRectMake(self.view.bounds.size.width/2-191.5, 0, 200, 40);
        numberPages.frame = CGRectMake(self.view.frame.size.width-263, 720, 80, 30);
    }
    
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
	if (CGSizeEqualToSize(lastAppearSize, CGSizeZero) == false)
	{
		if (CGSizeEqualToSize(lastAppearSize, self.view.bounds.size) == false)
		{
			[self updateScrollViewContentViews]; // Update content views
		}
        
		lastAppearSize = CGSizeZero; // Reset view size tracking
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
	
    [self performSelector:@selector(showDocument:) withObject:nil afterDelay:0.02];
	
    
#if (READER_DISABLE_IDLE == TRUE) // Option
    
	[UIApplication sharedApplication].idleTimerDisabled = YES;
    
#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
	lastAppearSize = self.view.bounds.size; // Track view size
    
#if (READER_DISABLE_IDLE == TRUE) // Option
    
	[UIApplication sharedApplication].idleTimerDisabled = NO;
    
#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif
    
	mainToolbar = nil; mainPagebar = nil;
    
	PdfScroll = nil;
    contentViews = nil; lastHideTime = nil;
    
	lastAppearSize = CGSizeZero; currentPage = 0;
    
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    gCurrentOrientation=interfaceOrientation;
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    
    PdfScroll.contentInset = UIEdgeInsetsZero;

	if (isVisible == NO) return; // iOS present modal bodge
    
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (printInteraction != nil) [printInteraction dismissAnimated:NO];
	}
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    float factor;
    [self zoomReset];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        factor=1;
        m_pdfview.frame=CGRectMake ((self.view.bounds.size.width-self.view.bounds.size.width/factor)/2, 5, self.view.bounds.size.width/factor, self.view.bounds.size.height-5);
        PdfScroll.frame=m_pdfview.frame;
        numberPages.frame = CGRectMake(m_pdfview.frame.size.width+m_pdfview.frame.origin.x-80, 950, 80, 40);
        openButton.frame = CGRectMake(m_pdfview.frame.size.width/2-100, 0, 200, 40);
        
        if(isMetadataVisible){
            [metadataContainer removeFromSuperview];
            [self.view addSubview:metadataContainer];
            m_pdfview.frame=CGRectMake (325, 0, self.view.bounds.size.width/1.75, self.view.bounds.size.height-5);
            PdfScroll.frame=m_pdfview.frame;
            metadataContainer.frame=CGRectMake(0, 0, 320, 1019);
            numberPages.frame = CGRectMake(m_pdfview.frame.size.width+m_pdfview.frame.origin.x-80, 950, 80, 40);
            openButton.frame = CGRectMake(m_pdfview.frame.size.width/2-100, 0, 200, 40);
        }
        
    } else {
        factor=1.75;
        m_pdfview.frame=CGRectMake ((self.view.bounds.size.width-self.view.bounds.size.width/factor)/2, 5, self.view.bounds.size.width/factor, self.view.bounds.size.height-5);
        
        numberPages.frame = CGRectMake(self.view.frame.size.width-263, 720, 80, 30);
        openButton.frame = CGRectMake(m_pdfview.frame.size.width/2-100, 0, 200, 40);
        
        if(isMetadataVisible){
            m_pdfview.frame=CGRectMake(320+(self.view.bounds.size.width-(320+m_pdfview.frame.size.width))/2, 0, m_pdfview.frame.size.width, m_pdfview.frame.size.height);
            PdfScroll.frame=m_pdfview.frame;
            
        }
        
    }
    
    
    
	if (isVisible == NO) return; // iOS present modal bodge
    
	[self updateScrollViewContentViews]; // Update content views
    
	lastAppearSize = CGSizeZero; // Reset view size tracking
    
    [mainToolbar adjustButtons:interfaceOrientation];
    PdfScroll.frame=m_pdfview.frame;
    [self centreView];

    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (isVisible == NO) return; // iOS present modal bodge
    
	if (fromInterfaceOrientation == self.interfaceOrientation) return;
    
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif
    
	[super didReceiveMemoryWarning];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Page Curl Animation methods

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    
    @try{
        // NSInteger page = [document.pageNumber integerValue];
        NSInteger maxPage = [document.pageCount integerValue];
        NSInteger minPage = 1; // Minimum
        CGPoint location = [recognizer locationInView:self.view];
        // [self showImageWithText:@"swipe" atPoint:location];
        
        if(mainToolbar.hidden==NO || mainPagebar.hidden==NO){
            [mainToolbar hideToolbar];
            //  [mainPagebar hidePagebar];
            if( mainPagebar.hidden==false){
                [mainPagebar removeFromSuperview];
                mainPagebar.hidden=true;
            }
        }
        
        
        if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
            // if(![self.searchTable.view isDescendantOfView:self.view ]) {
            location.x -= 220.0;
            NSLog(@"Swip Left");
            
            if ((maxPage > minPage) && (currentPage != maxPage))
            {
                [self TurnPageRight];
            }
            //  }
            
        }
        else if(recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
            //if(![self.searchTable.view isDescendantOfView:self.view ]) {
            location.x += 220.0;
            NSLog(@"Swip Right");
            
            if ((maxPage > minPage) && (currentPage > minPage))
            {
                [self TurnPageLeft];
            }
            // }
        }
        [m_pdfview setNeedsDisplay];
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"handleSwipeFrom" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
    
}

-(void)TurnPageLeft{
    CATransition *transition = [CATransition animation];
    [transition setDelegate:self];
    [transition setDuration:0.5f];
    
    [transition setSubtype:@"fromRight"];
    [transition setType:@"pageUnCurl"];
    [m_pdfview.layer addAnimation:transition forKey:@"UnCurlAnim"];
    
    
    //  [self showDocumentPage:currentPage-1];
    currentPage--;
    [numberPages setTitle:[NSString stringWithFormat:@"%d of %@",currentPage,document.pageCount] forState:UIControlStateNormal];
    [ m_pdfview OnPrevPage];
    
}
-(void)TurnPageRight{
    CATransition *transition = [CATransition animation];
    [transition setDelegate:self];
    [transition setDuration:0.5f];
    
    
    [transition setSubtype:@"fromRight"];
    [transition setType:@"pageCurl"];
    [m_pdfview.layer addAnimation:transition forKey:@"CurlAnim"];
    
    currentPage++;
    [numberPages setTitle:[NSString stringWithFormat:@"%d of %@",currentPage,document.pageCount] forState:UIControlStateNormal];
    // [self showDocumentPage:currentPage+1];
    [ m_pdfview OnNextPage];
}

-(void)ChangeFileOnSwipe:(NSInteger)newAttachId{
    
    @try
    {
        CCorrespondence *correspondence;
        if(self.menuId!=100)
        {
            correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
        }
        else
        {
            correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        }
        
        if(newAttachId<0){
            // self.attachmentId+=1;
        }
        else if(newAttachId >=correspondence.attachmentsList.count){
            // self.attachmentId-=1;
        }
        else{
            NSMutableArray* thumbnailrarray = [[NSMutableArray alloc] init];
            
            
            if (correspondence.attachmentsList.count>0)
            {
                for(CAttachment* doc in correspondence.attachmentsList)
                {
                    if([doc.FolderName isEqualToString:mainDelegate.FolderName]){
                        [thumbnailrarray addObject:doc];
                    }
                    
                    
                }
            }
            
            
            CAttachment *fileToOpen=thumbnailrarray[newAttachId];
            self.attachmentId=newAttachId;
            NSString *tempPdfLocation=[fileToOpen saveInCacheinDirectory:correspondence.Id fromSharepoint:mainDelegate.isSharepoint];
            // NSString *tempPdfLocation=[CParser loadPdfFile:fileToOpen.url inDirectory:correspondence.Id];
            if ([ReaderDocument isPDF:tempPdfLocation] == NO) // File must exist
            {
                //  [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
                [m_pdfview removeFromSuperview];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"Warning")
                                                                message:NSLocalizedString(@"Alert.Extension",@"Document extension not supported.")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
                                                      otherButtonTitles:nil, nil];
                [alert show];
                
            }else {
                
                ReaderDocument *newDocument=[self OpenPdfReader:tempPdfLocation];
                
                document=newDocument;
                
                contentViews = [NSMutableDictionary new];
                currentPage=0;
                for (UIView *view in self.view.subviews)
                {
                    if (![view isKindOfClass:[ReaderMainToolbar class]] && ![view isKindOfClass:[ReaderMainPagebar class]])
                        [view removeFromSuperview];
                }
                
                lastHideTime = [NSDate date];
                [self updateScrollViewContentViews];
                lastAppearSize = CGSizeZero;
                
                [self performSelector:@selector(showDocument:) withObject:nil afterDelay:0];
                [UIApplication sharedApplication].idleTimerDisabled = YES;
                mainPagebar.attachmentId=self.attachmentId;
                [mainPagebar updatePagebar];
            }
        }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"ChangeFileOnSwipe" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
    
}

-(ReaderDocument*) OpenPdfReader:(NSString *) pdfPath{
    NSString *phrase = nil; // Document password (for unlocking most encrypted PDF files)
    
    NSString *filePath = pdfPath;// [pdfs lastObject];
    assert(filePath != nil); // Path to last PDF file
    
    ReaderDocument *newDocument = [ReaderDocument withDocumentFilePath:filePath password:phrase];
    
    return newDocument;
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    lastContentOffset = scrollView.contentOffset.x;
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    __block NSInteger page = 0;
    
	CGFloat contentOffsetX = scrollView.contentOffset.x;
    
	[contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
     ^(id key, id object, BOOL *stop)
     {
         ReaderContentView *contentView = object;
         
         if (contentView.frame.origin.x == contentOffsetX)
         {
             page = contentView.tag; *stop = YES;
         }
     }
     ];
    
	if (page != 0){  // Show the page
        [self showDocumentPage:page];
        
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    	[self showDocumentPage:PdfScroll.tag]; // Show page
    
    	PdfScroll.tag = 0; // Clear page number tag
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
	if ([touch.view isKindOfClass:[PDFView class]]) return YES;
    
	return NO;
}

#pragma mark UIGestureRecognizer action methods

- (void)decrementPageNumber
{
    	if (PdfScroll.tag == 0) // Scroll view did end
    	{
            NSInteger page = [document.pageNumber integerValue];
    		NSInteger maxPage = [document.pageCount integerValue];
            NSInteger minPage = 1; // Minimum
    
    		if ((maxPage > minPage) && (page != minPage))
    		{
    			CGPoint contentOffset = PdfScroll.contentOffset;
    
    			contentOffset.x -= PdfScroll.bounds.size.width; // -= 1
    
    			[PdfScroll setContentOffset:contentOffset animated:YES];
    
    			PdfScroll.tag = (page - 1); // Decrement page number
    		}
    	}
}

- (void)incrementPageNumber
{
    	if (PdfScroll.tag == 0) // Scroll view did end
    	{
    		NSInteger page = [document.pageNumber integerValue];
    		NSInteger maxPage = [document.pageCount integerValue];
    		NSInteger minPage = 1; // Minimum
    
    		if ((maxPage > minPage) && (page != maxPage))
    		{
    			CGPoint contentOffset = PdfScroll.contentOffset;
    
    			contentOffset.x += PdfScroll.bounds.size.width; // += 1
    
    			[PdfScroll setContentOffset:contentOffset animated:YES];
    
    			PdfScroll.tag = (page + 1); // Increment page number
    		}
    	}
}

- (void)handleSingleTap:(UILongPressGestureRecognizer *)recognizer
{
    
    
	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds
        
		CGPoint point = [recognizer locationInView:recognizer.view];
        
		CGRect areaRect = CGRectInset(viewRect, TAP_AREA_SIZE, 0.0f); // Area
        
		if (CGRectContainsPoint(areaRect, point)) // Single tap is inside the area
		{
            
            if ([lastHideTime timeIntervalSinceNow] < -0.75) // Delay since hide
            {
                if ((mainToolbar.hidden == YES))
                {
                    [mainToolbar showToolbar];
                    //[mainPagebar showPagebar]; // Show
                    [self.view bringSubviewToFront:mainToolbar];
                }else{
                    [mainToolbar hideToolbar];
                    // [mainPagebar hidePagebar];
                    if( mainPagebar.hidden==false){
                        [mainPagebar removeFromSuperview];
                        mainPagebar.hidden=true;
                    }
                }
            }
            
            
			return;
		}
        
		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = TAP_AREA_SIZE;
		nextPageRect.origin.x = (viewRect.size.width - TAP_AREA_SIZE);
        
		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}
        
		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = TAP_AREA_SIZE;
        
		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

-(void)loadNewDocumentReader:(ReaderDocument *)newdocument attachementId:(NSInteger)attachementId{
    @try{
        [self.noteContainer removeFromSuperview];
        self.attachmentId=attachementId;
        document=newdocument;
        contentViews = [NSMutableDictionary new];
        currentPage=0;
        
        [m_pdfview removeFromSuperview];
        if( mainPagebar.hidden==false){
            [mainPagebar removeFromSuperview];
            mainPagebar.hidden=true;
        }
        
        
        [self performSelectorInBackground:@selector(updatePagebarByCorrespondence) withObject:nil];
        
        [self.view bringSubviewToFront:mainToolbar];
        
        lastHideTime = [NSDate date];
        [self updateScrollViewContentViews];
        lastAppearSize = CGSizeZero;
        
        [self performSelector:@selector(showDocument:) withObject:nil afterDelay:0];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"loadNewDocumentReader" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
}

-(void)updatePagebarByCorrespondence{
    
	[self.view addSubview:mainPagebar];
    
}

#pragma mark ReaderContentViewDelegate methods

- (void)contentView:(ReaderContentView *)contentView touchesBegan:(NSSet *)touches
{
	if ((mainToolbar.hidden == NO) || (mainPagebar.hidden == NO))
	{
		if (touches.count == 1) // Single touches only
		{
			UITouch *touch = [touches anyObject]; // Touch info
            
			CGPoint point = [touch locationInView:self.view]; // Touch location
            
			CGRect areaRect = CGRectInset(self.view.bounds, TAP_AREA_SIZE, TAP_AREA_SIZE);
            
			if (CGRectContainsPoint(areaRect, point) == false) return;
		}
        
		[mainToolbar hideToolbar];
        //[mainPagebar hidePagebar]; // Hide
        if( mainPagebar.hidden==false){
            [mainPagebar removeFromSuperview];
            mainPagebar.hidden=true;
        }
        [self.noteContainer removeFromSuperview];
		lastHideTime = [NSDate date];
	}
}

#pragma mark ReaderMainToolbarDelegate methods
-(void)AcceptReject:(NSString*)note viewController:(AcceptWithCommentViewController *)viewcontroller action:(CAction *)action{
    @try{
        
        CCorrespondence *correspondence;
        if(self.menuId!=100){
            correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
        }else{
            correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        }
        
        
        NSString* params = [NSString stringWithFormat:@"action=%@&correspondenceId=%@&token=%@&transferId=%@&note=%@&inboxId=%@",action.action,correspondence.Id,mainDelegate.user.token,correspondence.TransferId,note,correspondence.inboxId];
        
        NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
        NSString* url = [NSString stringWithFormat:@"http://%@?%@",serverUrl,params];
        NSString* urlTextEscaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *xmlUrl = [NSURL URLWithString:urlTextEscaped];
        NSData *xmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
        NSString *validationResultAction=[CParser ValidateWithData:xmlData];
        
        if(![validationResultAction isEqualToString:@"OK"])
        {
            if([validationResultAction isEqualToString:@"Cannot access to the server"])
            {
                CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:url];
                [mainDelegate.user addPendingAction:pa];
            }else
                
                [self ShowMessage:validationResultAction];
            
        }else {
            
            
            
            NSString* correspondenceUrl = [NSString stringWithFormat:@"http://%@?action=GetCorrespondences&token=%@&inboxIds=%d",serverUrl,mainDelegate.user.token,[correspondence.inboxId intValue]];
            NSURL *xmlUrl = [NSURL URLWithString:correspondenceUrl];
            NSData *menuXmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
            NSMutableDictionary *correspondences=[CParser loadCorrespondencesWithData:menuXmlData];
            
            ((CMenu*)mainDelegate.user.menu[mainDelegate.inboxForArchiveSelected]).correspondenceList=[correspondences objectForKey:[NSString stringWithFormat:@"%d",[correspondence.inboxId intValue]]];
            
            mainDelegate.searchModule.correspondenceList = [correspondences objectForKey:[NSString stringWithFormat:@"%d",[correspondence.inboxId intValue]]];
            
            [self ShowMessage:[NSString stringWithFormat:@"Action %@ successfuly done.",action.action]];
            
            
            
            
            
        }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ActionsTableViewController" function:@"executeAction" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
}

-(void)SignAndSendIt:(NSString*)action document:(ReaderDocument *)document note:(NSString *)note{
    
    CCorrespondence *correspondence;
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }
    
    
    NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
    
    
    
    
    NSString* searchUrl = [NSString stringWithFormat:@"http://%@?action=SignAndSend&token=%d&correspondenceId=%d&transferId=%d&inboxId=%@&loginName=%@&pdfFilePath=%@&pageNumber=%d&SiteId=%@&FileId=%@&FileUrl=%@&note=%@",serverUrl,mainDelegate.user.token.intValue,mainDelegate.corresponenceId.intValue,mainDelegate.transferId.intValue,correspondence.inboxId,mainDelegate.user.loginName,mainDelegate.docUrl,document.pageCount.intValue,mainDelegate.SiteId,mainDelegate.FileId,mainDelegate.FileUrl,note];
    
    NSString* strUrl = [searchUrl stringByReplacingOccurrencesOfString:@"%5C" withString:@"\\"];
    
    NSString* urlTextEscaped = [strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *xmlUrl = [NSURL URLWithString:urlTextEscaped];
    NSData *XmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
    
    NSString *validationResultAction=[CParser ValidateWithData:XmlData];
    
    if(![validationResultAction isEqualToString:@"OK"])
    {
        if([validationResultAction isEqualToString:@"Cannot access to the server"])
        {
            CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:searchUrl];
            [mainDelegate.user addPendingAction:pa];
        }else
            
            [self ShowMessage:validationResultAction];
        
    }else {
        
        [self ShowMessage:@"Action successfuly done."];
        
    }
    
}

-(void)destinationSelected:(CDestination*)dest withRouteLabel:(CRouteLabel*)routeLabel routeNote:(NSString*)note withDueDate:(NSString*)date viewController:(TransferViewController *)viewcontroller
{
    
	@try{
        CUser* userTemp =  mainDelegate.user ;
        
        CCorrespondence *correspondence;
        if(self.menuId!=100){
            correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
        }else{
            correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        }
        // CAttachment *currentDoc=correspondence.attachmentsList[self.attachmentId];
        
        NSString* url = [NSString stringWithFormat:@"action=TransferCorrespondence&token=%@&correspondenceId=%@&destinationId=%@&purposeId=%@&dueDate=%@&note=%@",userTemp.token,correspondence.TransferId,dest.rid,routeLabel.labelId,date,note];
        CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        
        [userTemp processSingleAction:pa];
            if(self.menuId !=100)
                [((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList removeObjectAtIndex:self.correspondenceId];
            
            NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
            NSString* correspondenceUrl = [NSString stringWithFormat:@"http://%@?action=GetCorrespondences&token=%@&inboxIds=%d",serverUrl,mainDelegate.user.token,[correspondence.inboxId intValue]];
            NSURL *xmlUrl = [NSURL URLWithString:correspondenceUrl];
            NSData *menuXmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
            
            NSMutableDictionary *correspondences=[CParser loadCorrespondencesWithData:menuXmlData];
            
            // ((CMenu*)mainDelegate.user.menu[mainDelegate.inboxForArchiveSelected]).correspondenceList=[correspondences objectForKey:[NSString stringWithFormat:@"%d",nb]];
            
            mainDelegate.searchModule.correspondenceList = [correspondences objectForKey:[NSString stringWithFormat:@"%d",[correspondence.inboxId intValue]]];
            
            
            [self ShowMessage:@"Transfer succesfully done"];
            
            
            
            if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
            {
                
                [viewcontroller dismissViewControllerAnimated:YES  completion:^{
                    [delegate dismissReaderViewController:self];
                }];
            }
            // Dismiss the ReaderViewController
            
        
        
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"destinationSelected" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
    
    
}

//
//-(BOOL)uploadXml:(NSString*) docId{
//    
//    BOOL isPerformed;
//    @try{
//        
//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
//                                                             NSUserDomainMask, YES);
//        NSString *documentsDirectory = [paths objectAtIndex:0];
//        NSString *documentsPath = [documentsDirectory
//                                   stringByAppendingPathComponent:@"annotations.xml"];
//        NSLog(@"%@",documentsPath);
//        
//        NSLog(@"Saving xml data to %@...", documentsPath);
//        
//        NSData *imageData= [NSData dataWithContentsOfFile:documentsPath] ;
//        // setting up the URL to post to
//        
//        NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
//        NSString* urlString = [NSString stringWithFormat:@"http://%@",serverUrl];
//        
//        // setting up the request object now
//        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//        [request setURL:[NSURL URLWithString:urlString]];
//        [request setHTTPMethod:@"POST"];
//        
//        
//        NSString *boundary = @"---------------------------14737809831466499882746641449";
//        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
//        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
//        
//        NSMutableData *body = [NSMutableData data];
//        
//        // action parameter
//        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"action\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[@"UpdateDocument" dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//        
//        
//        
//        // file
//        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[@"Content-Disposition: form-data; name=\"userfile\"; filename=\".xml\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[NSData dataWithData:imageData]];
//        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//        
//        // text parameter
//        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"correspondenceId\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[docId dataUsingEncoding:NSUTF8StringEncoding]];
//        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
//        
//        
//        // close form
//        [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//        
//        // set request body
//        [request setHTTPBody:body];
//        
//        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
//        
//        NSString *validationResult=[CParser ValidateWithData:returnData];
//        if(![validationResult isEqualToString:@"OK"]){
//            
//            if([validationResult isEqualToString:@"Cannot access to the server"]){
//                isPerformed=YES;
//                CCorrespondence *correspondence;
//                if(self.menuId!=100){
//                    correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
//                }else{
//                    correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
//                }
//                NSMutableArray* thumbnailrarray = [[NSMutableArray alloc] init];
//                
//                
//                if (correspondence.attachmentsList.count>0)
//                {
//                    for(CAttachment* doc in correspondence.attachmentsList)
//                    {
//                        if([doc.FolderName isEqualToString:mainDelegate.FolderName]){
//                            [thumbnailrarray addObject:doc];
//                        }
//                        
//                        
//                    }
//                }
//                
//                CAttachment *attachment=thumbnailrarray[self.attachmentId];
//                
//                NSData* annotData= [NSData dataWithContentsOfFile:attachment.tempPdfLocation];
//                [Base64 initialize];
//                NSString *annotString64=[Base64 encode:annotData];
//                NSError *error;
//                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
//                                                                     NSUserDomainMask, YES);
//                NSString *documentsDirectory = [paths objectAtIndex:0];
//                NSString *documentsPath = [documentsDirectory
//                                           stringByAppendingPathComponent:@"pending.xml"];
//                
//                NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:documentsPath];
//                
//                GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData
//                                         
//                                                                       options:0 error:&error];
//                
//                GDataXMLElement* rootEl  = [doc rootElement];
//                
//                if(rootEl==nil){
//                    rootEl =[GDataXMLNode elementWithName:@"Documents" stringValue:@""];
//                    
//                }
//                
//                GDataXMLElement * docEl=[GDataXMLNode elementWithName:@"Document" stringValue:@""];
//                
//                GDataXMLElement *correspondenceIdEl=[GDataXMLNode elementWithName:@"CorrespondenceId" stringValue:correspondence.Id];
//                [docEl addChild:correspondenceIdEl];
//                GDataXMLElement *docIdEl=[GDataXMLNode elementWithName:@"DocId" stringValue:attachment.docId];
//                [docEl addChild:docIdEl];
//                GDataXMLElement *urlEl=[GDataXMLNode elementWithName:@"Url" stringValue:attachment.url];
//                [docEl addChild:urlEl];
//                GDataXMLElement *contentEl=[GDataXMLNode elementWithName:@"Content" stringValue:annotString64];
//                [docEl addChild:contentEl];
//                [rootEl addChild:docEl];
//                
//                
//                GDataXMLDocument *document2 = [[GDataXMLDocument alloc]
//                                               initWithRootElement:rootEl] ;
//                NSData *xmlData2 = document2.XMLData;
//                
//                NSLog(@"Saving xml data to %@...", documentsPath);
//                [xmlData2 writeToFile:documentsPath atomically:YES];
//                
//                
//            }
//            else{ isPerformed=NO;
//                [self ShowMessage:validationResult];
//            }
//        }
//        else
//        {
//            
//            isPerformed=YES;
//            [mainDelegate.Highlights removeAllObjects];
//            [mainDelegate.Notes removeAllObjects];
//        }
//    }
//    @catch (NSException *ex) {
//        [FileManager appendToLogView:@"ReaderViewController" function:@"uploadXml" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
//    }
//	return isPerformed;
//}

-(void)uploadXml:(NSString*) docId{
    
    @try{
        if (mainDelegate==nil) mainDelegate=(AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Saving",@"Saving ...") maskType:SVProgressHUDMaskTypeBlack];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *documentsPath = [documentsDirectory
                                       stringByAppendingPathComponent:@"annotations.xml"];
            NSLog(@"%@",documentsPath);
            
            NSLog(@"Saving xml data to %@...", documentsPath);
            
            NSData *imageData= [NSData dataWithContentsOfFile:documentsPath] ;
            // setting up the URL to post to
            
            NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
            NSString* urlString = [NSString stringWithFormat:@"http://%@",serverUrl];
            
            // setting up the request object now
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            [request setURL:[NSURL URLWithString:urlString]];
            [request setHTTPMethod:@"POST"];
            
            
            NSString *boundary = @"---------------------------14737809831466499882746641449";
            NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
            [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
            
            NSMutableData *body = [NSMutableData data];
            
            // action parameter
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"action\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"SaveAnnotations" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            
            
            // file
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Disposition: form-data; name=\"annotations\"; filename=\".xml\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[NSData dataWithData:imageData]];
            [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            // text parameter
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"correspondenceId\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[docId dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            //token parameter
            [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"token\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[mainDelegate.user.token dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            
            // close form
            [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            
            // set request body
            [request setHTTPBody:body];
            
            NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                NSString *validationResult=[CParser ValidateWithData:returnData];
                if (mainDelegate==nil) mainDelegate=(AppDelegate*)[[UIApplication sharedApplication] delegate];
                if(![validationResult isEqualToString:@"OK"]){
                    
                    if([validationResult isEqualToString:@"Cannot access to the server"]){
                        [self ShowMessage:validationResult];
                    }
                    else{
                        [self ShowMessage:validationResult];
                    }
                }else{
                    [self ShowMessage:@"Saved Successfully"];
                    mainDelegate.isAnnotated=NO;
                    
                    //[self deleteCachedFiles];
                    
                }
                
                
            });
            
        });
    }
    @catch (NSException *ex) {
        [SVProgressHUD dismiss];
        [FileManager appendToLogView:@"ReaderViewController" function:@"uploadXml" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
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

-(void)tappedInSearch{
    
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
	{
        
		[delegate dismissReaderViewControllerToShowResult:self]; // Dismiss the ReaderViewController
        
	}
}
- (void)dismiss {
	[SVProgressHUD dismiss];
}

- (void)increaseProgress{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Signing",@"Signing ...") maskType:SVProgressHUDMaskTypeBlack];
    NSTimer* myTimer = [NSTimer scheduledTimerWithTimeInterval: 3.0 target: self
                                                      selector: @selector(dismiss) userInfo: nil repeats: NO];
    //[SVProgressHUD dismiss];
    
}


typedef enum{
    Highlight,Sign,Note,Erase,Save
    
} AnnotationsType;
-(void)performaAnnotation:(int)annotation{
    @try{
        CCorrespondence *correspondence;
        if(self.menuId!=100){
            correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
        }else{
            correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        }
        CAttachment *fileToOpen=correspondence.attachmentsList[self.attachmentId];
        [m_pdfview setAttachmentId:fileToOpen.AttachmentId.intValue];
        [self.notePopController dismissPopoverAnimated:YES];
        switch (annotation) {
            case Highlight:
                mainDelegate.isAnnotated=YES;
                [m_pdfview setBtnHighlight:YES];
                [m_pdfview setBtnNote:NO];
                [m_pdfview setBtnSign:NO];
                [m_pdfview setBtnErase:NO];
                break;
            case Sign:{
                mainDelegate.isAnnotated=YES;
                
                [m_pdfview setBtnHighlight:NO];
                [m_pdfview setBtnNote:NO];
                [m_pdfview setBtnSign:YES];
                [m_pdfview setBtnErase:NO];

                UIAlertView *alertOk=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Info",@"Info") message:NSLocalizedString(@"Alert.Sign",@"Click on pdf document to sign") delegate:self cancelButtonTitle:NSLocalizedString(@"OK",@"OK") otherButtonTitles: nil];
                [alertOk show];
                
            }
                break;
            case Note:{
                [m_pdfview setBtnErase:NO];
                [m_pdfview setBtnSign:NO];
                [m_pdfview setBtnNote:YES];
                [m_pdfview setBtnHighlight:NO];

                mainDelegate.isAnnotated=YES;
                NoteAlertView *noteView = [[NoteAlertView alloc] initWithFrame:CGRectMake(0, 300, 400, 250) fromComment:NO];
                noteView.modalPresentationStyle = UIModalPresentationFormSheet;
                noteView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [self presentViewController:noteView animated:YES completion:nil];
                noteView.view.superview.frame = CGRectMake(300, 300, 400, 250);
                UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
                if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
                    noteView.view.superview.frame = CGRectMake(150, 300, 400, 250);
                } else {
                    noteView.view.superview.frame = CGRectMake(300, 300, 400, 250);
                }
                
                noteView.delegate=self;
            }
                break;
            case Erase:
                [m_pdfview setBtnHighlight:NO];
                [m_pdfview setBtnNote:NO];
                [m_pdfview setBtnSign:NO];
                [m_pdfview setBtnErase:YES];
                break;
            case Save:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",@"Warning")
                                                                message:NSLocalizedString(@"Alert.SaveDoc",@"Saving annotaions will override the document. Are you sure you want to save?")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"NO",@"NO")
                                                      otherButtonTitles:NSLocalizedString(@"YES",@"YES"), nil];
                alert.tag=TAG_SAVE;
                [alert show];
            }
                break;
                
            default:
                break;
        }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"performaAnnotation" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
}
-(void)send:(NSString*)action note:(NSString*)note{
    
    mainDelegate.isAnnotated=YES;
    NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
    
    NSString* searchUrl;
    if([action isEqualToString:@"SendToPresident"])
        searchUrl = [NSString stringWithFormat:@"http://%@?action=%@&token=%d&correspondenceId=%d&transferId=%d&inboxId=%d",serverUrl,action,mainDelegate.user.token.intValue,mainDelegate.corresponenceId.intValue,mainDelegate.transferId.intValue,mainDelegate.inboxId.intValue];
    else
        searchUrl = [NSString stringWithFormat:@"http://%@?action=%@&token=%d&correspondenceId=%d&transferId=%d&inboxId=%d&note=%@",serverUrl,action,mainDelegate.user.token.intValue,mainDelegate.corresponenceId.intValue,mainDelegate.transferId.intValue,mainDelegate.inboxId.intValue,note];
    
    NSURL *xmlUrl = [NSURL URLWithString:[searchUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSData *XmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
    NSString *validationResultAction=[CParser ValidateWithData:XmlData];
    
    if(![validationResultAction isEqualToString:@"OK"])
    {
        if([validationResultAction isEqualToString:@"Cannot access to the server"])
        {
            CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:searchUrl];
            [mainDelegate.user addPendingAction:pa];
        }else
            
            [self ShowMessage:validationResultAction];
        
    }else {
        if((mainDelegate.selectedInbox-1)>=mainDelegate.user.menu.count)
            mainDelegate.selectedInbox=1;
        CMenu* currentInbox=((CMenu*)mainDelegate.user.menu[mainDelegate.selectedInbox-1]);
        NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
        NSString* correspondenceUrl = [NSString stringWithFormat:@"http://%@?action=GetCorrespondences&token=%@&inboxIds=%d",serverUrl,mainDelegate.user.token,currentInbox.menuId];
        NSURL *xmlUrl = [NSURL URLWithString:correspondenceUrl];
        NSData *menuXmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
        
        NSMutableDictionary *correspondences=[CParser loadCorrespondencesWithData:menuXmlData];
        
        // ((CMenu*)mainDelegate.user.menu[mainDelegate.inboxForArchiveSelected]).correspondenceList=[correspondences objectForKey:[NSString stringWithFormat:@"%d",nb]];
        
        mainDelegate.searchModule.correspondenceList = [correspondences objectForKey:[NSString stringWithFormat:@"%d",currentInbox.menuId]];
        //    correspondence.systemProperties=corr
        
        
        [self ShowMessage:@"Action successfuly done."];
        
    }
    
}



-(void)saveAnnotation
{
    mainDelegate.isAnnotated=NO;
//   if(mainDelegate.Highlights.count==0&&mainDelegate.Notes.count==0){
//            [self ShowMessage:NSLocalizedString(@"NothingToSave", @"nothing to save")];
//            [self dismiss];
//            return;
//        }
    @try {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Processing",@"Processing ...") maskType:SVProgressHUDMaskTypeBlack];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        CCorrespondence *correspondence;
        if(self.menuId!=100){
            correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
        }else{
            correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        }
        NSMutableArray* thumbnailrarray = [[NSMutableArray alloc] init];
        
        
        if (correspondence.attachmentsList.count>0)
        {
            for(CAttachment* doc in correspondence.attachmentsList)
            {
                if([doc.FolderName isEqualToString:mainDelegate.FolderName]){
                    [thumbnailrarray addObject:doc];
                }
                
                
            }
        }
        [mainDelegate.Notes addObjectsFromArray:mainDelegate.IncomingNotes];
        [mainDelegate.Highlights addObjectsFromArray:mainDelegate.IncomingHighlights];
        CAttachment *attachment=thumbnailrarray[self.attachmentId];
        //  mainDelegate.AnnotationSaved=YES;

        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *documentsPath = [documentsDirectory stringByAppendingPathComponent:@"annotations.xml"];
            GDataXMLElement* rootEl =[GDataXMLNode elementWithName:@"Annotations" stringValue:@""];
            if(mainDelegate.Notes.count>0 || mainDelegate.Highlights.count>0){
                GDataXMLElement *Height=[GDataXMLNode elementWithName:@"Height" stringValue:[NSString stringWithFormat:@"%f",[m_pdfview getHeight]]];
                GDataXMLElement *Width=[GDataXMLNode elementWithName:@"Width" stringValue:[NSString stringWithFormat:@"%f",[m_pdfview getWidth]]];
                GDataXMLElement * pageinfo=[GDataXMLNode elementWithName:@"PageInfo" stringValue:@""];
                GDataXMLElement * Size=[GDataXMLNode elementWithName:@"Size" stringValue:@""];
                
                
                [Size addChild:Height];
                [Size addChild:Width];
                [pageinfo addChild:Size];
                [rootEl addChild:pageinfo];}
            
            GDataXMLElement * NotesEl=[GDataXMLNode elementWithName:@"Notes" stringValue:@""];
            GDataXMLElement * HighlightsEl=[GDataXMLNode elementWithName:@"Highlights" stringValue:@""];
            for(note* note in mainDelegate.Notes){
                GDataXMLElement *docEl=[GDataXMLNode elementWithName:@"Note" stringValue:@""];
                GDataXMLElement* noteAttribute=[GDataXMLElement attributeWithName:@"status" stringValue:note.status];
                [docEl addAttribute:noteAttribute];
                GDataXMLElement *AttachmentId=[GDataXMLNode elementWithName:@"AttachmentId" stringValue:[NSString stringWithFormat:@"%d",note.AttachmentId]];
                [docEl addChild:AttachmentId];
                
                GDataXMLElement *pgnb=[GDataXMLNode elementWithName:@"page" stringValue:[NSString stringWithFormat:@"%d",note.PageNb]];
                [docEl addChild:pgnb];
                
                GDataXMLElement *x=[GDataXMLNode elementWithName:@"noteX" stringValue:[NSString stringWithFormat:@"%f",note.abscissa]];
                [docEl addChild:x];
                
                GDataXMLElement *y=[GDataXMLNode elementWithName:@"noteY" stringValue:[NSString stringWithFormat:@"%f",note.ordinate]];
                [docEl addChild:y];
                
                GDataXMLElement *notee=[GDataXMLNode elementWithName:@"noteMSG" stringValue:note.note];
                [docEl addChild:notee];
                
                [NotesEl addChild:docEl];
                
            }
            for(HighlightClass* obj in mainDelegate.Highlights){
                GDataXMLElement *docEl=[GDataXMLNode elementWithName:@"Highlight" stringValue:@""];
                GDataXMLElement* highlightAttribute=[GDataXMLElement attributeWithName:@"status" stringValue:obj.status];
                [docEl addAttribute:highlightAttribute];
                GDataXMLElement *pgnb=[GDataXMLNode elementWithName:@"page" stringValue:[NSString stringWithFormat:@"%d",obj.PageNb]];
                [docEl addChild:pgnb];
                
                GDataXMLElement *AttachmentId=[GDataXMLNode elementWithName:@"AttachmentId" stringValue:[NSString stringWithFormat:@"%d",obj.AttachmentId]];
                [docEl addChild:AttachmentId];
                GDataXMLElement *x=[GDataXMLNode elementWithName:@"HighlightX1" stringValue:[NSString stringWithFormat:@"%f",obj.abscissa]];
                [docEl addChild:x];
                
                GDataXMLElement *y=[GDataXMLNode elementWithName:@"HighlightY1" stringValue:[NSString stringWithFormat:@"%f",obj.ordinate]];
                [docEl addChild:y];
                
                GDataXMLElement *x1=[GDataXMLNode elementWithName:@"HighlightX2" stringValue:[NSString stringWithFormat:@"%f",obj.x1]];
                [docEl addChild:x1];
                
                GDataXMLElement *y1=[GDataXMLNode elementWithName:@"HighlightY2" stringValue:[NSString stringWithFormat:@"%f",obj.y1]];
                [docEl addChild:y1];
                [HighlightsEl addChild:docEl];
                
            }
            [rootEl addChild:NotesEl];
            [rootEl addChild:HighlightsEl];
            
            GDataXMLDocument *document2 = [[GDataXMLDocument alloc] initWithRootElement:rootEl] ;
            
            NSData *xmlData2 = document2.XMLData;
            
            [xmlData2 writeToFile:documentsPath atomically:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadXml:correspondence.Id];
                //[SVProgressHUD dismiss];
                //                [mainDelegate.Highlights removeAllObjects];
                //                [mainDelegate.Notes removeAllObjects];
                
            });
        });
        
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"saveAnnotation" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
    
    @finally {
        
    }
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar homeButton:(UIButton *)button
{
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
	{
        
		[delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
    }
    
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar attachmentButton:(UIButton *)button
{
    if(folderPagebar.hidden==YES){
        if(mainPagebar.hidden==YES||mainPagebar==nil){
            folderPagebar.hidden=false;
            
            [self.view bringSubviewToFront:folderPagebar];
        }
        else{
            folderPagebar.hidden = true;
            mainPagebar.hidden=true;
            [mainPagebar removeFromSuperview];
            
        }
    }
    else{
        [mainPagebar removeFromSuperview];
        mainPagebar.hidden=true;
        folderPagebar.hidden = true;
        
    }
    
    //    if(mainPagebar.hidden==YES){
    //        [mainPagebar showPagebar];
    //        [self.view bringSubviewToFront:mainPagebar];
    //    }
    //    else [mainPagebar hidePagebar];
}
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar lockButton:(UIButton *)button message:(NSString*)msg
{
    [self ShowMessage:msg];
}




- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar annotationButton:(UIButton *)button{
    
	AnnotationsTableViewController* noteController = [[AnnotationsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    CCorrespondence *correspondence;
    CAttachment *attachment;
    
    
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }	NSMutableArray *annotProperties=[[NSMutableArray alloc]init];
    NSMutableArray* thumbnailrarray = [[NSMutableArray alloc] init];
    
    
    if (correspondence.attachmentsList.count>0)
    {
        for(CAttachment* doc in correspondence.attachmentsList)
        {
            if([doc.FolderName isEqualToString:mainDelegate.FolderName]){
                [thumbnailrarray addObject:doc];
            }
            
            
        }
    }
    
    attachment = [thumbnailrarray objectAtIndex:mainDelegate.attachmentSelected];
    
    BOOL found=NO;
    
    if ([attachment.title rangeOfString:@".pdf"].location != NSNotFound) {
        found = YES;
    }
    
    for(id key in correspondence.toolbar){
        //jis signattachment
        if([key isEqualToString:@"Sign"]){
            
            
            
            if(mainDelegate.inboxForArchiveSelected!=0 && found && [attachment.isOriginalMail isEqualToString:@"YES"] ){
                
                [annotProperties addObject:key];
            }
            
        }
        
        if(([key isEqualToString:@"Highlight"] ||[key isEqualToString:@"Note"]) && [[correspondence.toolbar objectForKey:key] isEqualToString:@"YES"]){
            [annotProperties addObject:key];
        }
        
    }
	noteController.properties=annotProperties;
	noteController.delegate=self;
	self.notePopController = [[UIPopoverController alloc] initWithContentViewController:noteController];
	
	//size as needed
	self.notePopController.popoverContentSize = CGSizeMake(250, 50*annotProperties.count+100);
    
    
	[self.notePopController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar transferButton:(UIButton *)button{
    TransferViewController *transferView = [[TransferViewController alloc] initWithFrame:CGRectMake(0, 200, 450, 370)];
    transferView.modalPresentationStyle = UIModalPresentationFormSheet;
    transferView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:transferView animated:YES completion:nil];
    transferView.view.superview.frame = CGRectMake(300, 200, 450, 370); //it's important to do this after presentModalViewController
    // noteView.view.superview.center = self.view.center;
    transferView.delegate=self;
}
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar SignActionButton:(UIButton *)button{
    NSMutableArray *actionProperties=[[NSMutableArray alloc]init];
    CCorrespondence *correspondence;
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }
    for(CAction*  key in correspondence.SignActions){
        if([[correspondence.toolbar objectForKey:@"Sign"] isEqualToString:@"YES"])
            if(([key.action isEqualToString:@"Sign"] ||[key.action isEqualToString:@"SignAll"] || [key.action isEqualToString:@"FreeSign"] || [key.action isEqualToString:@"FreeSignAll"] || [key.action isEqualToString:@"SignAndSend"] )){
                [actionProperties addObject:key];
            }
    }
    // CCorrespondence *correspondence;
    
    NewActionTableViewController *newactionViewController=[[NewActionTableViewController alloc]initWithStyle:UITableViewStylePlain];
    // newactionViewController.action=correspondence.actions;
    self.notePopController = [[UIPopoverController alloc] initWithContentViewController:newactionViewController];
	
	//size as needed
	self.notePopController.popoverContentSize = CGSizeMake(250, 50*correspondence.SignActions.count);
    
    
	[self.notePopController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    newactionViewController.document=document;
    newactionViewController.m_pdfview=m_pdfview;
    newactionViewController.doc=m_pdfdoc;
    newactionViewController.SignAction=actionProperties;
    newactionViewController.delegate=self;
}
-(void)tappedInToolbar:(ReaderMainToolbar *)toolbar actionButton:(UIButton *)button{
    NSMutableArray *actionProperties=[[NSMutableArray alloc]init];
    CCorrespondence *correspondence;
    for(id key in correspondence.toolbar){
        if(([key isEqualToString:@"Accept"] ||[key isEqualToString:@"Reject"] || [key isEqualToString:@"Send"] || [key isEqualToString:@"Sign and Send"] )&&[[correspondence.toolbar objectForKey:key] isEqualToString:@"YES"]){
            [actionProperties addObject:key];
        }
    }
    // CCorrespondence *correspondence;
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }
    NewActionTableViewController *newactionViewController=[[NewActionTableViewController alloc]initWithStyle:UITableViewStylePlain];
    // newactionViewController.action=correspondence.actions;
    self.notePopController = [[UIPopoverController alloc] initWithContentViewController:newactionViewController];
	
	//size as needed
	self.notePopController.popoverContentSize = CGSizeMake(250, 50*correspondence.actions.count);
    
    
	[self.notePopController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    newactionViewController.document=document;
    newactionViewController.delegate=self;
}
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar actionsButton:(UIButton *)button
{
    
    CCorrespondence *correspondence;
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }
    NSMutableArray* thumbnailrarray = [[NSMutableArray alloc] init];
    
    
    if (correspondence.attachmentsList.count>0)
    {
        for(CAttachment* doc in correspondence.attachmentsList)
        {
            if([doc.FolderName isEqualToString:mainDelegate.FolderName]){
                [thumbnailrarray addObject:doc];
            }
            
            
        }
    }
    
    CAttachment *file=thumbnailrarray[self.attachmentId];
    
    ActionsTableViewController* actionController = [[ActionsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    actionController.document=document;
	actionController.correspondenceId=correspondence.Id;
    actionController.docId=file.docId;
	actionController.actions=correspondence.actions;
    
	self.notePopController = [[UIPopoverController alloc] initWithContentViewController:actionController];
	
	//size as needed
	self.notePopController.popoverContentSize = CGSizeMake(250, 50*correspondence.actions.count);
    
    
	[self.notePopController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    
    actionController.delegate=self;
    
}
-(void)PopUpCommentDialog:(UITableViewController*)viewcontroller Action:(CAction*)action{
    
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
    {
        [self.notePopController dismissPopoverAnimated:NO];
        AcceptWithCommentViewController *AcceptView = [[AcceptWithCommentViewController alloc] initWithActionName:CGRectMake(0, 200, 450, 370)  Action:action];
        
        AcceptView.modalPresentationStyle = UIModalPresentationFormSheet;
        AcceptView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:AcceptView animated:YES completion:nil];
        AcceptView.view.superview.frame = CGRectMake(300, 200, 450, 370); //it's important to do this after presentModalViewController
        // noteView.view.superview.center = self.view.center;
        AcceptView.delegate=self;
        
        // [delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
    }
}

-(void)PopUpCommentDialogWhenSign:(NewActionTableViewController*)viewcontroller Action:(CAction*)action document:(ReaderDocument*)document{
    
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
    {
        [self.notePopController dismissPopoverAnimated:NO];
        AcceptWithCommentViewController *AcceptView = [[AcceptWithCommentViewController alloc] initWithActionName:CGRectMake(0, 200, 450, 370)  Action:action];
        
        AcceptView.modalPresentationStyle = UIModalPresentationFormSheet;
        AcceptView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:AcceptView animated:YES completion:nil];
        AcceptView.view.superview.frame = CGRectMake(300, 200, 450, 370); //it's important to do this after presentModalViewController
        // noteView.view.superview.center = self.view.center;
        AcceptView.delegate=self;
        AcceptView.document =document;
        
        // [delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
    }
}

-(void)dismissPopUp:(NewActionTableViewController*)viewcontroller{
    [self.notePopController dismissPopoverAnimated:NO];
    
}
-(void)movehome:(TransferViewController *)viewcontroller{
    
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
    {
        [self.notePopController dismissPopoverAnimated:NO];
        [delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
    }
    
}
-(void)SignAndMovehome:(NewActionTableViewController *)viewcontroller{
    
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
    {
        [self.notePopController dismissPopoverAnimated:NO];
        [delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
    }
    
}
-(void)ActionMoveHome:(AcceptWithCommentViewController *)viewcontroller{
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
	{
        
        [delegate dismissReaderViewController:self];
    }
    
}

-(void)closeMetadata{
    float factor=1;

    [mainToolbar hideToolbar];
    //[mainPagebar hidePagebar];
    if( mainPagebar.hidden==false){
        [mainPagebar removeFromSuperview];
        mainPagebar.hidden=true;
    }
    [self.noteContainer removeFromSuperview];
    [metadataContainer removeFromSuperview];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        factor=1;
    }
    else
        factor=1.75;
    m_pdfview.frame=CGRectMake ((self.view.bounds.size.width-self.view.bounds.size.width/factor)/2, 5, self.view.bounds.size.width/factor, self.view.bounds.size.height-5);
    
    PdfScroll.frame=m_pdfview.frame;
    [self centreView];
    isMetadataVisible=!isMetadataVisible;
}


-(void)hide{
    [self closeMetadata];
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar metadataButton:(UIButton *)button
{
    @try{
        [mainToolbar hideToolbar];
        //[mainPagebar hidePagebar];
        if( mainPagebar.hidden==false){
            [mainPagebar removeFromSuperview];
            mainPagebar.hidden=true;
        }    if(isNoteVisible)
            [self.noteContainer removeFromSuperview];
        if(isMetadataVisible){
            [metadataContainer removeFromSuperview];
            m_pdfview.frame=CGRectMake ((self.view.bounds.size.width-self.view.bounds.size.width/1.75)/2, 5, self.view.bounds.size.width/1.75, self.view.bounds.size.height-5);
            PdfScroll.frame=m_pdfview.frame;
            
        }
        else{
            CGRect viewRect = CGRectMake(0,0, 320, self.view.bounds.size.height);
            CCorrespondence *correspondence;
            if(self.menuId!=100){
                correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
            }else{
                correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
            }
            MetadataViewController  *metadataTable=[[MetadataViewController alloc]initWithStyle:UITableViewStyleGrouped];
            metadataTable.view.frame=viewRect;
            
            
            metadataTable.currentCorrespondence=correspondence;
            
            
            
            [self addChildViewController:metadataTable];
            
            UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
            
            close.frame = CGRectMake(288, 10, 20, 20);
            [close setBackgroundImage:[UIImage imageNamed:@"delete_item.png"] forState:UIControlStateNormal];
            [close addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
            [close setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            
            
            metadataContainer=[[UIView alloc]initWithFrame:CGRectMake(0,0,320, self.view.bounds.size.height )];
            
            [metadataContainer addSubview:close];
            
            [metadataContainer addSubview:metadataTable.view];
            [metadataContainer bringSubviewToFront:close];
            [self.view addSubview:metadataContainer];
            m_pdfview.frame=CGRectMake(320+(self.view.bounds.size.width-(320+m_pdfview.frame.size.width))/2, 0, m_pdfview.frame.size.width, m_pdfview.frame.size.height);
            PdfScroll.frame=m_pdfview.frame;
            
            //jis orientation
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
                [metadataContainer removeFromSuperview];
                [self.view addSubview:metadataContainer];
                m_pdfview.frame=CGRectMake (325, 0, self.view.bounds.size.width/1.75, self.view.bounds.size.height-5);
                PdfScroll.frame=m_pdfview.frame;
                
                metadataContainer.frame=CGRectMake(0, 0, 320, 1019);
                numberPages.frame = CGRectMake(360, 950, 80, 40);
            }
            //endjis orientation
        }
        [self centreView];

        isMetadataVisible=!isMetadataVisible;
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"metadataButton" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
    
}
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar searchButton:(UIButton *)button
{
    //
    //    [self.noteContainer removeFromSuperview];
    //    for (UIView *view in theScrollView.subviews)
    //    {
    //        if ([view isKindOfClass:[ReaderContentView class]])
    //            view.hidden=YES;
    //    }
    //
    
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar commentButton:(UIButton *)button

{
    if(isNoteVisible)
        [self.noteContainer removeFromSuperview];
    else {
        CGRect viewRect = CGRectMake((self.view.bounds.size.width-520)/2,0, 520, self.view.bounds.size.height);
        NotesViewController *noteTable=[[NotesViewController alloc]initWithStyle:UITableViewStyleGrouped];
        noteTable.view.frame=viewRect;
        noteTable.menuId=self.menuId;
        noteTable.correspondenceId=self.correspondenceId;
        noteTable.attachmentId=self.attachmentId;
        [self addChildViewController:noteTable];
        self.noteContainer=[[UIView alloc]initWithFrame:CGRectMake(0, mainToolbar.frame.size.height,self.view.bounds.size.width, 300 )];
        self.noteContainer.backgroundColor = [UIColor colorWithRed:1/255.0f green:1/255.0f  blue:1/255.0f  alpha:0.9];
        CGRect shadowRect = self.view.bounds; shadowRect.origin.y += self.noteContainer.frame.origin.y+self.noteContainer.frame.size.height+ shadowRect.size.height; shadowRect.size.height = 10;
        
        UIXToolbarShadow *shadowView = [[UIXToolbarShadow alloc] initWithFrame:shadowRect];
        
        [self.noteContainer addSubview:shadowView];
        
        
        
        [self.noteContainer addSubview:noteTable.view];
        [self.view addSubview:self.noteContainer];
    }
    isNoteVisible=!isNoteVisible;
}
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar noteButton:(UIButton *)button
{
    
    
    NoteAlertView *noteView = [[NoteAlertView alloc] initWithFrame:CGRectMake(0, 300, 400, 250) fromComment:NO];
    noteView.modalPresentationStyle = UIModalPresentationFormSheet;
    noteView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:noteView animated:YES completion:nil];
    noteView.view.superview.frame = CGRectMake(300, 300, 400, 250); //it's important to do this after presentModalViewController
    // noteView.view.superview.center = self.view.center;
    noteView.delegate=self;
}

//jen PreviousNext
//- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar nextButton:(UIButton *)button documentReader:(ReaderDocument *)newdocument correspondenceId:(NSInteger)correspondenceId
//{
//    [self loadNewDocumentReader:newdocument documentId:correspondenceId];
//}
//
//- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar previousButton:(UIButton *)button documentReader:(ReaderDocument *)newdocument correspondenceId:(NSInteger)correspondenceId
//{
//    [self loadNewDocumentReader:newdocument documentId:correspondenceId];
//
//}
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar nextButton:(UIButton *)button documentReader:(ReaderDocument *)newdocument correspondenceId:(NSInteger)correspondenceId attachementId:(NSInteger)attachementId
{
    [self loadNewDocumentReader:newdocument attachementId:attachementId];
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar previousButton:(UIButton *)button documentReader:(ReaderDocument *)newdocument correspondenceId:(NSInteger)correspondenceId attachementId:(NSInteger)attachementId
{
    [self loadNewDocumentReader:newdocument attachementId:attachementId];
    
}




- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return  YES;
}




#pragma mark ThumbsViewControllerDelegate methods

- (void)dismissThumbsViewController:(ThumbsViewController *)viewController
{
	[self updateToolbarBookmarkIcon]; // Update bookmark icon
    
	[self dismissViewControllerAnimated:YES completion:nil]; // Dismiss
}

- (void)thumbsViewController:(ThumbsViewController *)viewController gotoPage:(NSInteger)page
{
	[self showDocumentPage:page]; // Show the page
}

#pragma mark ReaderMainPagebarDelegate methods

- (void)pagebar:(ReaderMainPagebar *)pagebar gotoPage:(NSInteger)page document:(ReaderDocument*)newdocument fileId:(NSInteger)fileId
{
    @try{
        document=newdocument;
        [numberPages setTitle:[NSString stringWithFormat:@"1 of %@",document.pageCount] forState:UIControlStateNormal];
        self.attachmentId=fileId;
        contentViews = [NSMutableDictionary new];
        currentPage=0;
        for (UIView *view in self.view.subviews)
        {
            if (![view isKindOfClass:[mainToolbar class]] && ![view isKindOfClass:[mainPagebar class]])
                [view removeFromSuperview];
        }
        
        lastHideTime = [NSDate date];
        [self updateScrollViewContentViews];
        lastAppearSize = CGSizeZero;
        [self performSelector:@selector(showDocument:) withObject:nil afterDelay:0];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        //[self showDocumentPage:page]; // Show the page
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"gotoPage" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
    
}

#pragma mark UIApplication notification methods

- (void)applicationWill:(NSNotification *)notification
{
	[document saveReaderDocument]; // Save any ReaderDocument object changes
    
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (printInteraction != nil) [printInteraction dismissAnimated:NO];
	}
}

#pragma mark search methods

//-(void)SearchDataFromPDF{
//    Searching=YES;
//
//    //[searchPopVC dismissPopoverAnimated:YES];
//   [self performSelectorInBackground:@selector(GetFirstPageWithResult) withObject:nil ];
//
//
//
//
//    //[self GetListOfSearchPage];
//}
//static float progress = 0.0f;
//-(void)GetFirstPageWithResult{
//    NSInteger lastPage=currentPage;
//    PDFDocRef = CGPDFDocumentCreateX((__bridge CFURLRef)document.fileURL,document.password);
//    float pages = CGPDFDocumentGetNumberOfPages(PDFDocRef);
//    for (i=0; i<pages; i++) {
//         //[self performSelectorOnMainThread:@selector(PerFormONMainThread:) withObject:[NSString stringWithFormat:@"%f",(i+1/pages)/pages] waitUntilDone:NO];
//        progress=(float)((i+1/pages)/pages);
//        [self performSelectorOnMainThread:@selector(increaseProgress:) withObject:[NSString stringWithFormat:@"%d/%d",i,(int)pages] waitUntilDone:YES];
//        PDFPageRef = CGPDFDocumentGetPage(PDFDocRef,i+1); // Get page
//        if ([[self selections] count]>0) {
//            // [alertmessage hideAlert];
//           // [self.am hideAlert];
//             [self performSelectorOnMainThread:@selector(dismissSuccess) withObject:nil waitUntilDone:YES];
//            currentPage= i+1;
//             contentViews = [NSMutableDictionary new];
//            [self showDocumentPage:currentPage];
//            return;
//        }
//    }
//     //[alertmessage hideAlert];
//     [self performSelectorOnMainThread:@selector(dismissError) withObject:nil waitUntilDone:YES];
//    //[self.am hideAlert];
//        currentPage=lastPage;
//     contentViews = [NSMutableDictionary new];
//    [self showDocumentPage:currentPage];
//    return;
//}




- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        //cancel clicked ...do your action
    }
    else if (buttonIndex == 1)
    {
        if(alertView.tag==TAG_DEV)
        {
            // [cview setAnnotationNoteMsg:[alertView textFieldAtIndex:0].text];
            
        }
        

        if(alertView.tag==TAG_SAVE){
            [m_pdfview setBtnHighlight:NO];
            [m_pdfview setBtnNote:NO];
            [m_pdfview setBtnSign:NO];
            [m_pdfview setBtnErase:NO];
            CCorrespondence *correspondence;
            if(self.menuId!=100){
                correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
            }else{
                correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
            }
            CAttachment *fileToOpen=correspondence.attachmentsList[self.attachmentId];
            [m_pdfview setAttachmentId:fileToOpen.AttachmentId.intValue];
            [self saveAnnotation];
        }
        else{
            
        }
        
    }
    
    
    else
    {
        UIAlertView *alertNoSig=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Info",@"Info") message:NSLocalizedString(@"Alert.NoSignature",@"No Signature Available,please configure a signature")delegate:self cancelButtonTitle:NSLocalizedString(@"OK",@"OK") otherButtonTitles: nil];
        [alertNoSig show];
    }
    
    
}

- (void)tappedSaveNoteText:(NSString*)text private:(BOOL)isPrivate{
    [m_pdfview setAnnotationNoteMsg:text];
    [m_pdfview setBtnHighlight:NO];
    [m_pdfview setBtnNote:YES];
    [m_pdfview setBtnSign:NO];
}

- (void)tappedSaveSignatureWithWidth:(NSString*)width withHeight:(NSString*)height withRed:(NSString *)red withGreen:(NSString *)green withBlue:(NSString *)blue{
    
    
    [Base64 initialize];
    NSData* imgData;
    UIImage *image=[UIImage imageWithData:[Base64 decode:mainDelegate.user.signature]];
    
    imgData=UIImageJPEGRepresentation([self changeColor:image withRed:red withGreen:green withBlue:blue], 1.0);
    
    
    [m_pdfdoc setSignatureData:imgData];
    [m_pdfview setBtnHighlight:NO];
    [m_pdfview setBtnNote:NO];
    [m_pdfview setBtnSign:YES];
    [m_pdfview setAnnotationSignHeight:[height integerValue]];
    [m_pdfview setAnnotationSignWidth:[width integerValue]];
    UIAlertView *alertOk=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Info",@"Info") message:NSLocalizedString(@"Alert.Sign",@"Click on pdf document to sign") delegate:self cancelButtonTitle:NSLocalizedString(@"OK",@"OK") otherButtonTitles: nil];
    [alertOk show];
    
    
}

- (UIImage *) changeColor: (UIImage *)img  withRed:(NSString *)red withGreen:(NSString *)green withBlue:(NSString *)blue{
    
    
    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContext(img.size);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [[UIColor colorWithRed:[red floatValue]/255.0f green:[green floatValue]/255.0f blue:[blue floatValue]/255.0f alpha:1.0]setFill];
    // [color setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeColor);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);
    
    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
}





- (void)increaseProgress:(NSString*)UpdateProgress{
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Loading",@"Loading ...") maskType:SVProgressHUDMaskTypeBlack];
    
}

@end





//@implementation ReaderPagebarShadow
//
//#pragma mark ReaderPagebarShadow class methods
//
//+ (Class)layerClass
//{
//    return [CAGradientLayer class];
//}
//
//#pragma mark ReaderPagebarShadow instance methods
//
//- (id)initWithFrame:(CGRect)frame
//{
//    if ((self = [super initWithFrame:frame]))
//    {
//        self.autoresizesSubviews = NO;
//        self.userInteractionEnabled = NO;
//        self.contentMode = UIViewContentModeRedraw;
//        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//        self.backgroundColor = [UIColor clearColor];
//
//        CAGradientLayer *layer = (CAGradientLayer *)self.layer;
//        //	 UIColor *blackColor = [UIColor colorWithWhite:0.42f alpha:1.0f];
//        //	 UIColor *clearColor = [UIColor colorWithWhite:0.42f alpha:0.0f];
//        UIColor *blackColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
//        UIColor *clearColor = [UIColor colorWithWhite:0.1f alpha:0.8f];
//        layer.colors = [NSArray arrayWithObjects:(id)clearColor.CGColor, (id)blackColor.CGColor, nil];
//    }
//    
//    return self;
//}
//
//@end
