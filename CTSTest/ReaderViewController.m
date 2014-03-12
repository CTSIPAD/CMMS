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
//#import "SVProgressHUD.h"

@interface ReaderViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate,
									ReaderMainToolbarDelegate, ReaderMainPagebarDelegate, ReaderContentViewDelegate, ThumbsViewControllerDelegate>
@end

@implementation ReaderViewController
{
	ReaderDocument *document;

    
	UIScrollView *theScrollView;

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
}

#pragma mark Constants

#define PAGING_VIEWS 3

#define TOOLBAR_HEIGHT 115.0f
#define PAGEBAR_HEIGHT 100.0f

#define TAP_AREA_SIZE 48.0f

#define TAG_DEV 1
#define TAG_SIGN 2
#define TAG_SAVE 3

#pragma mark Properties

@synthesize delegate,keyword,selections;

#pragma mark Support methods

- (void)updateScrollViewContentSize
{
    
	NSInteger count = [document.pageCount integerValue];

	if (count > PAGING_VIEWS) count = PAGING_VIEWS; // Limit

	CGFloat contentHeight = theScrollView.bounds.size.height;

	CGFloat contentWidth = (theScrollView.bounds.size.width * count);

	theScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (void)updateScrollViewContentViews
{
	[self updateScrollViewContentSize]; // Update the content size

	NSMutableIndexSet *pageSet = [NSMutableIndexSet indexSet]; // Page set

	[contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
		^(id key, id object, BOOL *stop)
		{
			ReaderContentView *contentView = object; [pageSet addIndex:contentView.tag];
		}
	];

	__block CGRect viewRect = CGRectZero; viewRect.size = theScrollView.bounds.size;

	__block CGPoint contentOffset = CGPointZero; NSInteger page = [document.pageNumber integerValue];

	[pageSet enumerateIndexesUsingBlock: // Enumerate page number set
		^(NSUInteger number, BOOL *stop)
		{
			NSNumber *key = [NSNumber numberWithInteger:number]; // # key

			ReaderContentView *contentView = [contentViews objectForKey:key];

			contentView.frame = viewRect; if (page == number) contentOffset = viewRect.origin;

			viewRect.origin.x += viewRect.size.width; // Next view frame position
		}
	];

	if (CGPointEqualToPoint(theScrollView.contentOffset, contentOffset) == false)
	{
		theScrollView.contentOffset = contentOffset; // Update content offset
	}
}

- (void)updateToolbarBookmarkIcon
{
	NSInteger page = [document.pageNumber integerValue];

	BOOL bookmarked = [document.bookmarks containsIndex:page];

	[mainToolbar setBookmarkState:bookmarked]; // Update
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

		CGRect viewRect = CGRectZero; viewRect.size = theScrollView.bounds.size;

		for (NSInteger number = minValue; number <= maxValue; number++)
		{
			NSNumber *key = [NSNumber numberWithInteger:number]; // # key

			ReaderContentView *contentView = [contentViews objectForKey:key];

			if (contentView == nil) // Create a brand new document content view
			{
				//NSURL *fileURL = document.fileURL; NSString *phrase = document.password; // Document properties

				//contentView = [[ReaderContentView alloc] initWithFrame:viewRect fileURL:fileURL page:number password:phrase];
                m_pdfview = [[PDFView alloc]initWithFrame:viewRect];
                [m_pdfdoc setPDFView:m_pdfview];
                [m_pdfdoc setCurPage:[m_pdfdoc getPDFPage:number]];
                [m_pdfview initPDFDoc:m_pdfdoc];
               
                //Add pdf view to viewcontroller.
               // [self.view addSubview:m_pdfview];

				//[theScrollView addSubview:contentView];
               // [contentViews setObject:contentView forKey:key];

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

		if (CGPointEqualToPoint(theScrollView.contentOffset, contentOffset) == false)
		{
			theScrollView.contentOffset = contentOffset; // Update content offset
		}

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
    CAttachment *fileToOpen=correspondence.attachmentsList[self.attachmentId];
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
            } else {
                factor=1.75;
            }

            m_pdfview = [[PDFView alloc]initWithFrame:CGRectMake((self.view.bounds.size.width-self.view.bounds.size.width/factor)/2, 5, self.view.bounds.size.width/factor, self.view.bounds.size.height-5)];
            [m_pdfdoc setPDFView:m_pdfview];
            [m_pdfview initPDFDoc:m_pdfdoc];
            [self.view addSubview:m_pdfview];
        }
        else{
	[m_pdfdoc setPDFView:m_pdfview];
	[m_pdfview initPDFDoc:m_pdfdoc];
        }
//
//	//Add pdf view to viewcontroller.
       
        
	
    [self.view bringSubviewToFront:mainToolbar];
    [self.view bringSubviewToFront:mainPagebar];
    [self updateScrollViewContentSize];
    }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"showDocument" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
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

- (void)viewDidLoad
{
	[super viewDidLoad];

	assert(document != nil); // Must have a valid ReaderDocument

	//self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    self.view.backgroundColor=[UIColor colorWithRed:29/255.0f green:29/255.0f  blue:29/255.0f  alpha:1.0];
	CGRect viewRect = self.view.bounds; // View controller's view bounds

	theScrollView = [[UIScrollView alloc] initWithFrame:viewRect]; // All

	theScrollView.scrollsToTop = NO;
	theScrollView.pagingEnabled = YES;
	theScrollView.delaysContentTouches = NO;
	theScrollView.showsVerticalScrollIndicator = NO;
	theScrollView.showsHorizontalScrollIndicator = NO;
    theScrollView.scrollEnabled=NO;
	theScrollView.contentMode = UIViewContentModeRedraw;
	theScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	theScrollView.backgroundColor = [UIColor clearColor];
	theScrollView.userInteractionEnabled = YES;
	theScrollView.autoresizesSubviews = NO;
	theScrollView.delegate = self;

	//[self.view addSubview:theScrollView];

	CGRect toolbarRect = viewRect;
	toolbarRect.size.height = TOOLBAR_HEIGHT;

	mainToolbar = [[ReaderMainToolbar alloc] initWithFrame:toolbarRect document:document CorrespondenceId:self.correspondenceId MenuId:self.menuId AttachmentId:self.attachmentId]; // At top
	mainToolbar.delegate = self;

	[self.view addSubview:mainToolbar];
    
    [mainToolbar hideToolbar];
	CGRect pagebarRect = viewRect;
	pagebarRect.size.height = PAGEBAR_HEIGHT;
	pagebarRect.origin.y = (viewRect.size.height - PAGEBAR_HEIGHT);

	mainPagebar = [[ReaderMainPagebar alloc] initWithFrame:pagebarRect Document:document CorrespondenceId:self.correspondenceId MenuId:self.menuId AttachmentId:self.attachmentId]; // At bottom

	mainPagebar.delegate = self;

	[self.view addSubview:mainPagebar];
    
    [mainPagebar hidePagebar];

	UILongPressGestureRecognizer *singleTapOne = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	//singleTapOne.numberOfTouchesRequired = 1;
    //singleTapOne.numberOfTapsRequired = 1; singleTapOne.delegate = self;
   // singleTapOne.cancelsTouchesInView=YES;
	[self.view addGestureRecognizer:singleTapOne];

	UITapGestureRecognizer *doubleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapOne.numberOfTouchesRequired = 1; doubleTapOne.numberOfTapsRequired = 2; doubleTapOne.delegate = self;
	[self.view addGestureRecognizer:doubleTapOne];
    
    UIPinchGestureRecognizer *twoFingerPinch = [[UIPinchGestureRecognizer alloc]
                                                initWithTarget:self
                                                action:@selector(twoFingerPinch:)];
    [self.view addGestureRecognizer:twoFingerPinch];


	UITapGestureRecognizer *doubleTapTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapTwo.numberOfTouchesRequired = 2; doubleTapTwo.numberOfTapsRequired = 2; doubleTapTwo.delegate = self;
	[self.view addGestureRecognizer:doubleTapTwo];

	[singleTapOne requireGestureRecognizerToFail:doubleTapOne]; // Single tap requires double tap to fail
    
    UISwipeGestureRecognizer *swipeRecognizerLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    swipeRecognizerLeft.direction=UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeRecognizerLeft];
    
    UISwipeGestureRecognizer *swipeLeftRecognizerRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
   swipeLeftRecognizerRight.direction=UISwipeGestureRecognizerDirectionRight;
   [self.view addGestureRecognizer:swipeLeftRecognizerRight];
    
    UISwipeGestureRecognizer *swipeRecognizerUp=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    swipeRecognizerUp.direction=UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeRecognizerUp];
    
    UISwipeGestureRecognizer *swipeRecognizerDown=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    swipeRecognizerDown.direction=UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeRecognizerDown];
  

	contentViews = [NSMutableDictionary new]; lastHideTime = [NSDate date];
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

	if (CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero)) // First time
	{
		[self performSelector:@selector(showDocument:) withObject:nil afterDelay:0.02];
	}

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

	theScrollView = nil; contentViews = nil; lastHideTime = nil;

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
   
    
	if (isVisible == NO) return; // iOS present modal bodge

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (printInteraction != nil) [printInteraction dismissAnimated:NO];
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
//    if([self.searchTable.view isDescendantOfView:self.view ]) {
//        CGRect searchViewRect = CGRectMake((self.view.bounds.size.width-450)/2, 0, 450, self.view.bounds.size.height);
//        self.searchTable.view.frame=searchViewRect;
//         }
//   
    
//    CGRect noteViewRect = CGRectMake((self.view.bounds.size.width-500)/2, 0, 500, self.view.bounds.size.height);
//    self.noteTable.view.frame=noteViewRect;
    float factor;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        factor=1;
    } else {
        factor=1.75;
    }
    
    m_pdfview.frame=CGRectMake ((self.view.bounds.size.width-self.view.bounds.size.width/factor)/2, 5, self.view.bounds.size.width/factor, self.view.bounds.size.height-5);
    
	if (isVisible == NO) return; // iOS present modal bodge

	[self updateScrollViewContentViews]; // Update content views

	lastAppearSize = CGSizeZero; // Reset view size tracking
    
      [mainToolbar adjustButtons:interfaceOrientation];
    
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//if (isVisible == NO) return; // iOS present modal bodge

	//if (fromInterfaceOrientation == self.interfaceOrientation) return;
  
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
        [mainPagebar hidePagebar];
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
        
        if ((maxPage > minPage) && (currentPage >= minPage))
        {
            [self TurnPageLeft];
        }
        // }
    }
    else if(recognizer.direction == UISwipeGestureRecognizerDirectionDown){
        
       // self.attachmentId -=1;
        
        CATransition *transition = [CATransition animation];
        [transition setDelegate:self];
        [transition setDuration:0.5f];
        
        [transition setType:kCATransitionFromTop];
        [transition setSubtype:kCATransitionFromTop];
        
        [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        
        
        [self.view.layer addAnimation:transition forKey:@"any"];
        [self ChangeFileOnSwipe: self.attachmentId-1];
    }
    else if(recognizer.direction == UISwipeGestureRecognizerDirectionUp){
       // self.attachmentId +=1;
        
        CATransition *transition = [CATransition animation];
        [transition setDelegate:self];
        [transition setDuration:0.5f];
        
        [transition setType:kCATransitionFromBottom];
        [transition setSubtype:kCATransitionFromBottom];
        
        [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        
        
        [self.view.layer addAnimation:transition forKey:@"any"];
        [self ChangeFileOnSwipe:self.attachmentId+1];
    }
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
   // [self showDocumentPage:currentPage+1];
     [ m_pdfview OnNextPage];
}

-(void)ChangeFileOnSwipe:(NSInteger)newAttachId{
    
    @try{
    

    CCorrespondence *correspondence;
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }
    
    if(newAttachId<0){
       // self.attachmentId+=1;
    }
   else if(newAttachId >=correspondence.attachmentsList.count){
        // self.attachmentId-=1;
    }
    else{
       CAttachment *fileToOpen=correspondence.attachmentsList[newAttachId];
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
	[self showDocumentPage:theScrollView.tag]; // Show page

	theScrollView.tag = 0; // Clear page number tag
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
	if (theScrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [document.pageNumber integerValue];
		NSInteger maxPage = [document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != minPage))
		{
			CGPoint contentOffset = theScrollView.contentOffset;

			contentOffset.x -= theScrollView.bounds.size.width; // -= 1

			[theScrollView setContentOffset:contentOffset animated:YES];

			theScrollView.tag = (page - 1); // Decrement page number
		}
	}
}

- (void)incrementPageNumber
{
	if (theScrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [document.pageNumber integerValue];
		NSInteger maxPage = [document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != maxPage))
		{
			CGPoint contentOffset = theScrollView.contentOffset;

			contentOffset.x += theScrollView.bounds.size.width; // += 1

			[theScrollView setContentOffset:contentOffset animated:YES];

			theScrollView.tag = (page + 1); // Increment page number
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
                        [mainPagebar hidePagebar];
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

- (void)twoFingerPinch:(UIPinchGestureRecognizer *)recognizer
{
    //    NSLog(@"Pinch scale: %f", recognizer.scale);
    CGRect viewRect = recognizer.view.bounds; // View bounds
    
    CGPoint point = [recognizer locationInView:recognizer.view];
    
    CGRect zoomArea = CGRectInset(viewRect, TAP_AREA_SIZE, TAP_AREA_SIZE);
    
        

    if (recognizer.scale >1.0f && recognizer.scale < 2.5f) {
        CGAffineTransform transform = CGAffineTransformMakeScale(recognizer.scale, recognizer.scale);
        
        if (CGRectContainsPoint(zoomArea, point))
        {
            //NSInteger page = [document.pageNumber integerValue];
            
           // NSNumber *key = [NSNumber numberWithInteger:page];
            
            //ReaderContentView *targetView = [contentViews objectForKey:key];
        m_pdfview.transform = transform;
        }
    }
}



- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect zoomArea = CGRectInset(viewRect, TAP_AREA_SIZE, TAP_AREA_SIZE);

		if (CGRectContainsPoint(zoomArea, point)) // Double tap is in the zoom area
		{
			//NSInteger page = [document.pageNumber integerValue]; // Current page #

			//NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			//ReaderContentView *targetView = [contentViews objectForKey:key];

			switch (recognizer.numberOfTouchesRequired) // Touches count
			{
				case 1: // One finger double tap: zoom ++
				{
					//[targetView zoomIncrement];
                    [m_pdfview OnZoomIn];
                    break;
				}

				case 2: // Two finger double tap: zoom --
				{
					//[targetView zoomDecrement];
                    [m_pdfview OnZoomOut];
                    break;
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

-(void)loadNewDocumentReader:(ReaderDocument *)newdocument documentId:(NSInteger)documentId{
    @try{
    [self.noteContainer removeFromSuperview];
    self.correspondenceId=documentId;
    self.attachmentId=0;
    document=newdocument;
    contentViews = [NSMutableDictionary new];
    currentPage=0;
   // Searching=NO;
//    for (UIView *view in self.view.subviews)
//    {
//        if ([view isKindOfClass:[UIImageView class]])
//            [view removeFromSuperview];
//    }
    [m_pdfview removeFromSuperview];
    [mainPagebar removeFromSuperview];
    
    
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
    CGRect viewRect = self.view.bounds;
    CGRect pagebarRect = viewRect;
	pagebarRect.size.height = PAGEBAR_HEIGHT;
	pagebarRect.origin.y = (viewRect.size.height - PAGEBAR_HEIGHT);
    mainPagebar = [[ReaderMainPagebar alloc] initWithFrame:pagebarRect  Document:document CorrespondenceId:self.correspondenceId MenuId:self.menuId AttachmentId:self.attachmentId]; // At bottom
    mainPagebar.delegate = self;
    
	[self.view addSubview:mainPagebar];
    [mainPagebar hidePagebar];
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

		[mainToolbar hideToolbar]; [mainPagebar hidePagebar]; // Hide
[self.noteContainer removeFromSuperview];
		lastHideTime = [NSDate date];
	}
}

#pragma mark ReaderMainToolbarDelegate methods

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
    
	NSString* url = [NSString stringWithFormat:@"action=TransferCorrespondence&token=%@&correspondenceId=%@&destinationId=%@&purposeId=%@&dueDate=%@&note=%@",userTemp.token,correspondence.Id,dest.rid,routeLabel.labelId,date,note];
	CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:url];
	
	
	[userTemp processSingleAction:pa];
    if([self uploadXml:correspondence.Id]){
      if(self.menuId !=100)
        [((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList removeObjectAtIndex:self.correspondenceId];
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
	{
        
        [viewcontroller dismissViewControllerAnimated:YES  completion:^{
            [delegate dismissReaderViewController:self];
        }];
    }
		 // Dismiss the ReaderViewController
        
    }
    
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"destinationSelected" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
   
   
}

-(BOOL)uploadXml:(NSString*) docId{
    	
    BOOL isPerformed;
    @try{
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
    [body appendData:[@"UpdateDocument" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    

    
    // file
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"userfile\"; filename=\".xml\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // text parameter
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"correspondenceId\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[docId dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    // close form
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // set request body
    [request setHTTPBody:body];
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
    NSString *validationResult=[CParser ValidateWithData:returnData];
    if(![validationResult isEqualToString:@"OK"]){
        
        if([validationResult isEqualToString:@"Cannot access to the server"]){
            isPerformed=YES;
            CCorrespondence *correspondence;
            if(self.menuId!=100){
                correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
            }else{
                correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
            }
            CAttachment *attachment=correspondence.attachmentsList[self.attachmentId];
            
            NSData* annotData= [NSData dataWithContentsOfFile:attachment.tempPdfLocation];
            [Base64 initialize];
            NSString *annotString64=[Base64 encode:annotData];
            NSError *error;
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *documentsPath = [documentsDirectory
                                       stringByAppendingPathComponent:@"pending.xml"];
            
            NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:documentsPath];
            
            GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData
                                     
                                                                   options:0 error:&error];

            GDataXMLElement* rootEl  = [doc rootElement];
            
            if(rootEl==nil){
                rootEl =[GDataXMLNode elementWithName:@"Documents" stringValue:@""];
                
            }
            
            GDataXMLElement * docEl=[GDataXMLNode elementWithName:@"Document" stringValue:@""];
                
                GDataXMLElement *correspondenceIdEl=[GDataXMLNode elementWithName:@"CorrespondenceId" stringValue:correspondence.Id];
                [docEl addChild:correspondenceIdEl];
                GDataXMLElement *docIdEl=[GDataXMLNode elementWithName:@"DocId" stringValue:attachment.docId];
                [docEl addChild:docIdEl];
                GDataXMLElement *urlEl=[GDataXMLNode elementWithName:@"Url" stringValue:attachment.url];
                [docEl addChild:urlEl];
                GDataXMLElement *contentEl=[GDataXMLNode elementWithName:@"Content" stringValue:annotString64];
                [docEl addChild:contentEl];
                [rootEl addChild:docEl];
           
            
            GDataXMLDocument *document2 = [[GDataXMLDocument alloc]
                                           initWithRootElement:rootEl] ;
            NSData *xmlData2 = document2.XMLData;
            
            NSLog(@"Saving xml data to %@...", documentsPath);
            [xmlData2 writeToFile:documentsPath atomically:YES];
            
            
        }
        else{ isPerformed=NO;
            [self ShowMessage:validationResult];
        }
    }
    else{isPerformed=YES;}
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"uploadXml" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
	return isPerformed;
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

typedef enum{
    Highlight,Sign,Note,Erase,Save
    
} AnnotationsType;
-(void)performaAnnotation:(int)annotation{
    @try{
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
//            UIAlertView *pinAlertView=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Signature.PinCode",@"Pin Code") message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") otherButtonTitles:NSLocalizedString(@"OK",@"OK"), nil];
//            pinAlertView.alertViewStyle=UIAlertViewStylePlainTextInput;
//            pinAlertView.tag=TAG_SIGN;
//            
//            UITextField* txtPin = [pinAlertView textFieldAtIndex:0];
//            txtPin.clearButtonMode = UITextFieldViewModeWhileEditing;
//            txtPin.keyboardType = UIKeyboardTypeNumberPad;
//            txtPin.secureTextEntry=YES;
//            
//            [pinAlertView show];
            
            ManageSignatureViewController *signatureView = [[ManageSignatureViewController alloc] initWithFrame:CGRectMake(300, 200, 400, 350) ];
            

            signatureView.modalPresentationStyle = UIModalPresentationFormSheet;
            signatureView.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [self presentViewController:signatureView animated:YES completion:nil];
            UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
            if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
                signatureView.view.superview.frame = CGRectMake(150, 200, 400, 350);
            } else {
               signatureView.view.superview.frame = CGRectMake(300, 200, 400, 350);
            }
            
            
            signatureView.delegate=self;
        }
            break;
        case Note:{
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



-(void)saveAnnotation
{
    mainDelegate.isAnnotated=NO;
    @try {
        CCorrespondence *correspondence;
        if(self.menuId!=100){
            correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
        }else{
            correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        }
        CAttachment *attachment=correspondence.attachmentsList[self.attachmentId];
        //  mainDelegate.AnnotationSaved=YES;
        NSString* dir  = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString* path = [dir stringByAppendingString:@"/FoxitSaveAnnotation.pdf"];
        
        
        NSData* annotData= [NSData dataWithContentsOfFile:path];
        [Base64 initialize];
        NSString *annotString64=[Base64 encode:annotData];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *documentsPath = [documentsDirectory
                                   stringByAppendingPathComponent:@"annotations.xml"];
        
        NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:documentsPath];
        
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData
         
                                                               options:0 error:&error];
        BOOL isFound=NO;
        GDataXMLElement* rootEl  = [doc rootElement];
    	
        if(rootEl==nil){
            rootEl =[GDataXMLNode elementWithName:@"Documents" stringValue:@""];
            
        }
       
    NSArray *allDocuments=[rootEl elementsForName:@"Document"];
        GDataXMLElement *docEl;
    if(allDocuments.count>0){
        for(docEl in allDocuments){
        
            NSArray *correspondenceIds=[docEl elementsForName:@"CorrespondenceId"];
            GDataXMLElement *correspondenceIdEl=[correspondenceIds objectAtIndex:0];
            
            NSArray *docIds=[docEl elementsForName:@"DocId"];
            GDataXMLElement *docIdEl=[docIds objectAtIndex:0];
            
            if([correspondenceIdEl.stringValue isEqualToString:correspondence.Id] && [docIdEl.stringValue isEqualToString:attachment.docId]){
                isFound=YES;
                NSArray *contents=[docEl elementsForName:@"Content"];
                GDataXMLElement *contentEl;
                if(contents.count>0){
                    contentEl=[contents objectAtIndex:0];
                    contentEl.stringValue=annotString64;
                }
            }
           
            
        }
        
    }
        
        if(isFound==NO){
            docEl=[GDataXMLNode elementWithName:@"Document" stringValue:@""];
            
            GDataXMLElement *correspondenceIdEl=[GDataXMLNode elementWithName:@"CorrespondenceId" stringValue:correspondence.Id];
            [docEl addChild:correspondenceIdEl];
            GDataXMLElement *docIdEl=[GDataXMLNode elementWithName:@"DocId" stringValue:attachment.docId];
            [docEl addChild:docIdEl];
            GDataXMLElement *urlEl=[GDataXMLNode elementWithName:@"Url" stringValue:attachment.url];
            [docEl addChild:urlEl];
           GDataXMLElement *contentEl=[GDataXMLNode elementWithName:@"Content" stringValue:annotString64];
            [docEl addChild:contentEl];
            [rootEl addChild:docEl];
        }
    
        GDataXMLDocument *document2 = [[GDataXMLDocument alloc]
                                       initWithRootElement:rootEl] ;
        NSData *xmlData2 = document2.XMLData;
        
        NSLog(@"Saving xml data to %@...", documentsPath);
        [xmlData2 writeToFile:documentsPath atomically:YES];
        
        
        
        NSFileManager* fileManager=[NSFileManager defaultManager];
       // NSError *cpError;
       // [fileManager removeItemAtPath:self.filePath error:nil];
       // [fileManager copyItemAtPath:path toPath:self.filePath error:&cpError];
        //  NSLog(@"%@",cpError);
        
        if ( [[NSFileManager defaultManager] isReadableFileAtPath:path] ){
            [fileManager removeItemAtPath:attachment.tempPdfLocation error:nil];
            [[NSFileManager defaultManager] copyItemAtPath:path toPath:attachment.tempPdfLocation error:nil];
        }
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
    if(mainPagebar.hidden==YES){
        [mainPagebar showPagebar];
        [self.view bringSubviewToFront:mainPagebar];
    }
    else [mainPagebar hidePagebar];
}
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar lockButton:(UIButton *)button message:(NSString*)msg
{
    [self ShowMessage:msg];
}




- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar annotationButton:(UIButton *)button{
    
	AnnotationsTableViewController* noteController = [[AnnotationsTableViewController alloc] initWithStyle:UITableViewStylePlain];

    CCorrespondence *correspondence;
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }	NSMutableArray *annotProperties=[[NSMutableArray alloc]init];
    for(id key in correspondence.toolbar){
        if(([key isEqualToString:@"Highlight"] || [key isEqualToString:@"Sign"] ||[key isEqualToString:@"Note"]) && [[correspondence.toolbar objectForKey:key] isEqualToString:@"YES"]){
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

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar actionsButton:(UIButton *)button
{
    
    CCorrespondence *correspondence;
    if(self.menuId!=100){
        correspondence= ((CMenu*)mainDelegate.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
    }
    
        CAttachment *file=correspondence.attachmentsList[self.attachmentId];
    
    ActionsTableViewController* actionController = [[ActionsTableViewController alloc] initWithStyle:UITableViewStylePlain];
    
	actionController.correspondenceId=correspondence.Id;
    actionController.docId=file.docId;
	actionController.actions=correspondence.actions;

	self.notePopController = [[UIPopoverController alloc] initWithContentViewController:actionController];
	
	//size as needed
	self.notePopController.popoverContentSize = CGSizeMake(250, 50*correspondence.actions.count);
    
    
	[self.notePopController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];

    

}


- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar metadataButton:(UIButton *)button
{
    @try{
    [mainToolbar hideToolbar];
    [mainPagebar hidePagebar];
    if(isNoteVisible)
        [self.noteContainer removeFromSuperview];
    if(isMetadataVisible){
        [metadataContainer removeFromSuperview];
        m_pdfview.frame=CGRectMake ((self.view.bounds.size.width-self.view.bounds.size.width/1.75)/2, 5, self.view.bounds.size.width/1.75, self.view.bounds.size.height-5);
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
    metadataContainer=[[UIView alloc]initWithFrame:CGRectMake(0,0,320, self.view.bounds.size.height )];
    //   self.noteContainer.backgroundColor = [UIColor colorWithRed:1/255.0f green:1/255.0f  blue:1/255.0f  alpha:0.9];
    
    [metadataContainer addSubview:metadataTable.view];
    [self.view addSubview:metadataContainer];
    m_pdfview.frame=CGRectMake(320+(self.view.bounds.size.width-(320+m_pdfview.frame.size.width))/2, 0, m_pdfview.frame.size.width, m_pdfview.frame.size.height);
        }
    
    isMetadataVisible=!isMetadataVisible;
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"ReaderViewController" function:@"metadataButton" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }

}
- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar searchButton:(UIButton *)button
{
 
    [self.noteContainer removeFromSuperview];
    for (UIView *view in theScrollView.subviews)
    {
        if ([view isKindOfClass:[ReaderContentView class]])
            view.hidden=YES;
    }
    

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


- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar nextButton:(UIButton *)button documentReader:(ReaderDocument *)newdocument correspondenceId:(NSInteger)correspondenceId
{
    [self loadNewDocumentReader:newdocument documentId:correspondenceId];
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar previousButton:(UIButton *)button documentReader:(ReaderDocument *)newdocument correspondenceId:(NSInteger)correspondenceId
{
    [self loadNewDocumentReader:newdocument documentId:correspondenceId];
    
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


- (void)dismiss {
	[SVProgressHUD dismiss];
}



- (void)increaseProgress:(NSString*)UpdateProgress{

    [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Loading",@"Loading ...") maskType:SVProgressHUDMaskTypeBlack];
  
}

@end
