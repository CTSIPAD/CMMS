//
//	ReaderMainToolbar.m
//	Reader v2.6.1
//
//	Created by Julius Oklamcak on 2011-07-01.
//	Copyright © 2011-2012 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
#import "ReaderViewController.h"
#import "GDataXMLNode.h"
#import "ReaderConstants.h"
#import "ReaderMainToolbar.h"
#import "ReaderDocument.h"
#import"CUser.h"
#import"CMenu.h"
#import"CCorrespondence.h"
#import"CAttachment.h"
#import"CFolder.h"
#import "AppDelegate.h"
#import "CParser.h"
#import "CSearch.h"
#import "TransferViewController.h"
#import <MessageUI/MessageUI.h>
#import "CFPendingAction.h"

@implementation ReaderMainToolbar
{
	UIButton *markButton;

	UIImage *markImageN;
	UIImage *markImageY;

    
    NSInteger correspondencesCount;
    //jen PreviousNext
    NSInteger attachementsCount;
    AppDelegate *mainDelegate;
    NSString* pageName;
    CCorrespondence *correspondence;
}
@synthesize nextButton,previousButton,actionsButton,transferButton,attachmentButton,metadataButton,lockButton,commentsButton,annotationButton,lblTitle,closeButton,actionButton;
#pragma mark Constants

#define BUTTON_X 8.0f
#define BUTTON_Y 8.0f
#define BUTTON_SPACE 8.0f
#define BUTTON_HEIGHT 30.0f

#define DONE_BUTTON_WIDTH 56.0f
#define THUMBS_BUTTON_WIDTH 40.0f
#define PRINT_BUTTON_WIDTH 40.0f
#define EMAIL_BUTTON_WIDTH 40.0f
#define MARK_BUTTON_WIDTH 40.0f

#define TITLE_HEIGHT 28.0f

#pragma mark Properties

@synthesize delegate;

#pragma mark ReaderMainToolbar instance methods

- (id)initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame document:nil CorrespondenceId:0 MenuId:0 AttachmentId:0];
}

- (id)initWithFrame:(CGRect)frame document:(ReaderDocument *)object CorrespondenceId:(NSInteger)correspondenceId MenuId:(NSInteger)menuId AttachmentId:(NSInteger)attachmentId
{
	assert(object != nil); // Must have a valid ReaderDocument
	if ((self = [super initWithFrame:frame]))
	{
        
        closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeButton setTintColor:[UIColor whiteColor]];
        [closeButton setTitle:[NSString stringWithFormat:@"Hide Menu"] forState:UIControlStateNormal];
        [closeButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, -80,0)];
        [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        closeButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [closeButton setBackgroundImage:[UIImage imageNamed:@"arrowup2.png"] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(hideToolbar) forControlEvents:UIControlEventTouchUpInside];
        
        


        
        
        [self addSubview:closeButton];
        
        self.menuId=menuId;
        self.correspondenceId=correspondenceId;
        self.attachmentId=attachmentId;
        NSInteger btnWidth=80;
        NSInteger leftButtonX=10;
       
        
        mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        self.user=mainDelegate.user;
        
        if(menuId!=100){
            correspondence=((CMenu*)self.user.menu[menuId]).correspondenceList[correspondenceId];
             correspondencesCount=((CMenu*)self.user.menu[menuId]).correspondenceList.count;
            //jen PreviousNext
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

            attachementsCount=thumbnailrarray.count;
        }else{
            
            correspondence=mainDelegate.searchModule.correspondenceList[mainDelegate.searchSelected];
             correspondencesCount=mainDelegate.searchModule.correspondenceList.count;
            //jen PreviousNext
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

            //attachementsCount=thumbnailrarray.count;
            attachementsCount=correspondence.attachmentsList.count;

        }
        
        lblTitle=[[UILabel alloc]initWithFrame:CGRectMake(20, 15, self.frame.size.width, 15)];
        lblTitle.font = [UIFont fontWithName:@"Helvetica" size:12];
        lblTitle.textColor=[UIColor colorWithRed:204/255.0f green:233/255.0f blue:247/255.0f alpha:1.0];

        [self addSubview:lblTitle];
        
       homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        homeButton.frame = CGRectMake(leftButtonX, 30, btnWidth, 90);
        [homeButton setBackgroundImage:[UIImage imageNamed:@"HomeIcon.png"] forState:UIControlStateNormal];

        [homeButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 10, 0,10)];
        [homeButton setTitle:NSLocalizedString(@"Menu.Home",@"Home") forState:UIControlStateNormal];
        homeButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:14];
        [homeButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [homeButton addTarget:self action:@selector(homeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
      
        [self addSubview:homeButton];
        
       
        
  
         CGFloat viewWidth = self.frame.size.width;
        CGFloat rightButtonX = viewWidth;
        
        nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButtonX -= (65 + 10);
        nextButton.frame = CGRectMake(rightButtonX, 30, 65, 90);
        [nextButton setBackgroundImage: [UIImage imageNamed:@"next.png"] forState:UIControlStateNormal];
        [nextButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 0, 0,0)];
        [nextButton setTitle:NSLocalizedString(@"Menu.Next",@"Next") forState:UIControlStateNormal];
        nextButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:13];
        [nextButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [nextButton setTitleColor:[UIColor grayColor]forState:UIControlStateDisabled];
         [nextButton addTarget:self action:@selector(nextButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
       //jen PreviousNext
        if(attachmentId==attachementsCount-1){
            nextButton.enabled=FALSE;
        }
        else  nextButton.enabled=TRUE;
      
        previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButtonX -= (65 + 10);
        previousButton.frame = CGRectMake(rightButtonX, 30, 65, 90);
         [previousButton setBackgroundImage: [UIImage imageNamed:@"previous.png"] forState:UIControlStateNormal];
        [previousButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 0, 0,0)];
        [previousButton setTitle:NSLocalizedString(@"Menu.Previous",@"Previous") forState:UIControlStateNormal];
        previousButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:13];
        [previousButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [previousButton setTitleColor:[UIColor grayColor]forState:UIControlStateDisabled];
       [previousButton addTarget:self action:@selector(previousButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
         if([[correspondence.toolbar objectForKey:@"NextPrevious"] isEqualToString:@"YES"]){
             [self addSubview:previousButton];
             [self addSubview:nextButton];
         }
        //jen PreviousNext
//        if(correspondenceId==0){
//            previousButton.enabled=FALSE;
//        }
        if(attachmentId==0){
            previousButton.enabled=FALSE;
        }
        else  previousButton.enabled=TRUE;
        
        lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButtonX -= (65 + 10);
        lockButton.frame = CGRectMake(rightButtonX, 30, 65, 90);

        if(correspondence.Locked==YES){
            [lockButton setBackgroundImage: [UIImage imageNamed:@"Unlock.png"] forState:UIControlStateNormal];
            [lockButton setBackgroundImage: [UIImage imageNamed:@"Lock.png"] forState:UIControlStateSelected];
             [lockButton setTitle:NSLocalizedString(@"Menu.Unlock",@"unlock") forState:UIControlStateNormal];
            
        }
        else{
            [lockButton setBackgroundImage: [UIImage imageNamed:@"Lock.png"] forState:UIControlStateNormal];
             [lockButton setBackgroundImage: [UIImage imageNamed:@"Unlock.png"] forState:UIControlStateSelected];
             [lockButton setTitle:NSLocalizedString(@"Menu.Lock",@"lock") forState:UIControlStateNormal];
            
        }

        [lockButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 0, 0,0)];
       
        lockButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:13];
        [lockButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [lockButton setTitleColor:[UIColor grayColor]forState:UIControlStateDisabled];
        [lockButton addTarget:self action:@selector(lockButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

        [self updateToolbar];
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
   [self adjustButtons:orientation];


	return self;
}

-(void)adjustButtons:(UIInterfaceOrientation)orientation{
     correspondence=mainDelegate.searchModule.correspondenceList[mainDelegate.searchSelected];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        lockButton.frame=CGRectMake(560, 30, 65, 90);
       previousButton.frame=CGRectMake(630, 30, 65, 90);
         nextButton.frame = CGRectMake(700,30, 65, 90);
//        closeButton.frame = CGRectMake(570,100, 200, 40);
        if([[correspondence.toolbar objectForKey:@"NextPrevious"] isEqualToString:@"NO"])
            closeButton.frame = CGRectMake(680,30, 65, 65);
        else
            closeButton.frame = CGRectMake(560,30, 65, 65);
    } else {
         lockButton.frame=CGRectMake(810, 30, 65, 90);
        previousButton.frame=CGRectMake(880, 30, 65, 90);
         nextButton.frame = CGRectMake(950, 30, 65, 90);
        if([[correspondence.toolbar objectForKey:@"NextPrevious"] isEqualToString:@"NO"])
            closeButton.frame = CGRectMake(930, 30, 65, 65);
        else
            closeButton.frame = CGRectMake(805, 30, 65, 65);
        //lblTitle.frame = CGRectMake(0, 15, 1024, 15);
    }
}

-(void)desableButtons{
    [annotationButton removeFromSuperview];
    [transferButton removeFromSuperview];
}

- (void)setBookmarkState:(BOOL)state
{
#if (READER_BOOKMARKS == TRUE) // Option

	if (state != markButton.tag) // Only if different state
	{
		if (self.hidden == NO) // Only if toolbar is visible
		{
			UIImage *image = (state ? markImageY : markImageN);

			[markButton setImage:image forState:UIControlStateNormal];
		}

		markButton.tag = state; // Update bookmarked state tag
	}

	if (markButton.enabled == NO) markButton.enabled = YES;

#endif // end of READER_BOOKMARKS Option
}

- (void)updateBookmarkImage
{
#if (READER_BOOKMARKS == TRUE) // Option

	if (markButton.tag != NSIntegerMin) // Valid tag
	{
		BOOL state = markButton.tag; // Bookmarked state

		UIImage *image = (state ? markImageY : markImageN);

		[markButton setImage:image forState:UIControlStateNormal];
	}

	if (markButton.enabled == NO) markButton.enabled = YES;

#endif // end of READER_BOOKMARKS Option
}

- (void)hideToolbar
{
	if (self.hidden == NO)
	{
       
        
		[UIView animateWithDuration:0.25 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.alpha = 0.0f;
			}
			completion:^(BOOL finished)
			{
				self.hidden = YES;
			}
		];
	}
}

- (void)showToolbar
{
	if (self.hidden == YES)
	{
		//[self updateBookmarkImage]; // First

		[UIView animateWithDuration:0.25 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.hidden = NO;
				self.alpha = 1.0f;
			}
			completion:NULL
		];
	}
}

-(ReaderDocument*) OpenPdfReader:(NSString *) pdfPath{
    NSString *phrase = nil; // Document password (for unlocking most encrypted PDF files)
    
    NSString *filePath = pdfPath;// [pdfs lastObject];
    assert(filePath != nil); // Path to last PDF file
    
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:filePath password:phrase];
    
    return document;
}


#pragma mark UIButton action methods
- (void)SignAction:(UIButton *)button
{

	[delegate tappedInToolbar:self SignActionButton:button];
}

- (void)homeButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self homeButton:button];
}

- (void)actionsButtonTapped:(UIButton *)button
{
   
	[delegate tappedInToolbar:self actionsButton:button];
}

- (void)commentButtonTapped:(UIButton *)button
{
[delegate tappedInToolbar:self commentButton:button];
}
- (void)metadataButtonTapped:(UIButton *)button
{
    
	[delegate tappedInToolbar:self metadataButton:button];
    
   
}

- (void)attachmentButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self attachmentButton:button];
}

- (void)annotationButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self annotationButton:button];
}
//jen (accept..)
-(void)actionButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self actionButton:button];
}
- (void)transferButtonTapped:(UIButton *)button
{
  [delegate tappedInToolbar:self transferButton:button];
  
}
BOOL lockSelected=NO;
- (void)lockButtonTapped:(UIButton *)button
{
    
    lockSelected=!lockSelected;
    if(lockSelected){
        lockButton.selected=YES;
    }else  lockButton.selected=NO;
    if(correspondence.Locked==NO){
         if([self performLock:@"LockCorrespondence"])
         [lockButton setTitle:NSLocalizedString(@"Menu.Unlock",@"unlock") forState:UIControlStateNormal];
        if(self.menuId !=100)
        ((CCorrespondence*) ((CMenu*)self.user.menu[self.menuId]).correspondenceList[self.correspondenceId]).Locked=YES;
    }
    else{  if([self performLock:@"UnlockCorrespondence"])
         [lockButton setTitle:NSLocalizedString(@"Menu.Lock",@"lock") forState:UIControlStateNormal];
        if(self.menuId !=100)
         ((CCorrespondence*) ((CMenu*)self.user.menu[self.menuId]).correspondenceList[self.correspondenceId]).Locked=NO;
       
    }
 // [delegate tappedInToolbar:self lockButton:button];
    
}

-(BOOL)performLock:(NSString*)action{
    
    BOOL isPerformed=NO;
    AppDelegate *appDelegate=(AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
    NSString* url=[NSString stringWithFormat:@"action=%@&token=%@&correspondenceId=%@",action,appDelegate.user.token,correspondence.Id];
    NSString* lockUrl = [NSString stringWithFormat:@"http://%@?%@",serverUrl,url];
    NSURL *xmlUrl = [NSURL URLWithString:lockUrl];
    NSData *lockXmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
    
    NSString *validationResult=[CParser ValidateWithData:lockXmlData];
    if(![validationResult isEqualToString:@"OK"]){
        if([validationResult isEqualToString:@"Cannot access to the server"])
        {isPerformed=YES;
            
            CFPendingAction*pa = [[CFPendingAction alloc] initWithActionUrl:url];
            [appDelegate.user addPendingAction:pa];
        }else
            [delegate tappedInToolbar:self lockButton:nil message:validationResult];
    }
    else isPerformed=YES;
    
    return isPerformed;
}


- (void)nextButtonTapped :(UIButton *)button
{
    //jen PreviousNext
    CAttachment *fileToOpen;
   // self.correspondenceId=self.correspondenceId+1;
    self.attachmentId=self.attachmentId+1;

    
     mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    mainDelegate.attachmentType = @"nextprevioustype";
    
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        //jen PreviousNext
       // NSMutableArray* thumbnailrarray = [[NSMutableArray alloc] init];
        
        
//        if (correspondence.attachmentsList.count>0)
//        {
//            for(CAttachment* doc in correspondence.attachmentsList)
//            {
//                if([doc.FolderName isEqualToString:mainDelegate.FolderName]){
//                    [thumbnailrarray addObject:doc];
//                }
//                
//                
//            }
//        }

   
    fileToOpen=correspondence.attachmentsList[self.attachmentId];
    [self updateTitleWithLocation:fileToOpen.location withName:fileToOpen.title];

    //jis next
    [self performSelectorOnMainThread:@selector(increaseProgress) withObject:@"" waitUntilDone:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

    if([fileToOpen.url isEqualToString:@""]){
       
        [mainDelegate.folderNames addObject:fileToOpen.FolderName];
        
        NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
        
        int docId = [correspondence.Id intValue];
        
        NSString* attachmentUrl = [NSString stringWithFormat:@"http://%@?action=GetFolderAttachments&token=%@&docId=%d&folderName=%@",serverUrl,mainDelegate.user.token,docId,fileToOpen.FolderName];
        
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
                NSString *tempPdfLocation=[fileToOpen saveInCacheinDirectory:fileToOpen.docId fromSharepoint:mainDelegate.isSharepoint];
                //  NSString *tempPdfLocation=[CParser loadPdfFile:fileToOpen.url inDirectory:correspondence.Id];
                ReaderDocument *newdocument=nil;
                if ([ReaderDocument isPDF:tempPdfLocation] == YES) // File must exist
                {
                    newdocument=[self OpenPdfReader:tempPdfLocation];
                }
                
                //jen PreviousNext
                //[delegate tappedInToolbar:self nextButton:button documentReader:newdocument correspondenceId:self.correspondenceId];
                [delegate tappedInToolbar:self nextButton:button documentReader:newdocument correspondenceId:self.correspondenceId attachementId:self.attachmentId];
                
                if(self.attachmentId==attachementsCount-1){
                    button.enabled=FALSE;
                }
                else  button.enabled=TRUE;
                
                if(self.attachmentId==0){
                    previousButton.enabled=FALSE;
                }
                else  previousButton.enabled=TRUE;
                lockSelected=NO;
                [self updateToolbar];
                [SVProgressHUD dismiss];

            });
        });
        

    
    
    
      }
- (void)increaseProgress{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Alert.Downloading",@"Downloading ...") maskType:SVProgressHUDMaskTypeBlack];
    
    
}
- (void)previousButtonTapped :(UIButton *)button
{
    //jen PreviousNExt
    CAttachment *fileToOpen;
    //self.correspondenceId=self.correspondenceId-1;
    
    mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    mainDelegate.attachmentType = @"nextprevioustype";
    
    self.attachmentId=self.attachmentId-1;
    
    if(self.menuId!=100){
        correspondence= ((CMenu*)self.user.menu[self.menuId]).correspondenceList[self.correspondenceId];
        //jen
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

        fileToOpen=thumbnailrarray[self.attachmentId];
    }else{
        correspondence=mainDelegate.searchModule.correspondenceList[self.correspondenceId];
        //jen
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

        //fileToOpen=thumbnailrarray[self.attachmentId];
    }
    
    fileToOpen=correspondence.attachmentsList[self.attachmentId];
    [self updateTitleWithLocation:fileToOpen.location withName:fileToOpen.title];
    //jen
    // NSString *tempPdfLocation=[fileToOpen saveInCacheinDirectory:correspondence.Id fromSharepoint:mainDelegate.isSharepoint];
    NSString *tempPdfLocation=[fileToOpen saveInCacheinDirectory:fileToOpen.docId fromSharepoint:mainDelegate.isSharepoint];
   // NSString *tempPdfLocation=[CParser loadPdfFile:fileToOpen.url inDirectory:correspondence.Id];

    ReaderDocument *document=nil;
    if ([ReaderDocument isPDF:tempPdfLocation] == YES) // File must exist
    {
        document=[self OpenPdfReader:tempPdfLocation];
    }
//jen PreviousNext
	//[delegate tappedInToolbar:self previousButton:button documentReader:document correspondenceId:self.correspondenceId];
    [delegate tappedInToolbar:self previousButton:button documentReader:document correspondenceId:self.correspondenceId attachementId:self.attachmentId];
//    if(self.correspondenceId==0){
//        button.enabled=FALSE;
//    
//    }
    if(self.attachmentId==0){
            button.enabled=FALSE;
            }
    else  button.enabled=TRUE;
    
//    if(self.correspondenceId==correspondencesCount-1){
//        nextButton.enabled=FALSE;
//    }
    if(self.attachmentId==attachementsCount-1){
        nextButton.enabled=FALSE;
    }
    else  nextButton.enabled=TRUE;
    
   lockSelected=NO;
    [self updateToolbar];
}



-(void)updateToolbar{
    NSInteger btnWidth=80;
    NSInteger leftButtonX=90;
    [metadataButton removeFromSuperview];
    [attachmentButton removeFromSuperview];
    [transferButton removeFromSuperview];
    [commentsButton removeFromSuperview];
    [annotationButton removeFromSuperview];
    [actionsButton removeFromSuperview];
    //[acceptButton removeFromSuperview];
    //[rejectButton removeFromSuperview];
    //[sendButton removeFromSuperview];
    [actionButton removeFromSuperview];
    if([[correspondence.toolbar objectForKey:@"Metadata"] isEqualToString:@"YES"]){
        metadataButton = [UIButton buttonWithType:UIButtonTypeCustom];
        metadataButton.frame = CGRectMake(leftButtonX, 30, btnWidth, 90);
        [metadataButton setBackgroundImage:[UIImage imageNamed:@"metadata.png"] forState:UIControlStateNormal];
        [metadataButton setTitle:NSLocalizedString(@"Menu.Metadata",@"Metadata") forState:UIControlStateNormal];
        [metadataButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 2, 0,2)];
        
        metadataButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:14];
        [metadataButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [metadataButton addTarget:self action:@selector(metadataButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:metadataButton];
        leftButtonX=leftButtonX+btnWidth;
    }
    if([[correspondence.toolbar objectForKey:@"Attachments"] isEqualToString:@"YES"]){
        attachmentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        attachmentButton.frame = CGRectMake(leftButtonX, 30, btnWidth, 90);
        [attachmentButton setBackgroundImage:[UIImage imageNamed:@"attachments.png"] forState:UIControlStateNormal];
        [attachmentButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 0, 0,0)];
        
        
        [attachmentButton setTitle:NSLocalizedString(@"Menu.Attachments",@"Attachments") forState:UIControlStateNormal];
        attachmentButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:14];
        [attachmentButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [attachmentButton addTarget:self action:@selector(attachmentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:attachmentButton];
        leftButtonX=leftButtonX+btnWidth;
    }
    
    if([[correspondence.toolbar objectForKey:@"Comments"] isEqualToString:@"YES"]){
        commentsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        commentsButton.frame = CGRectMake(leftButtonX, 30, btnWidth, 90);
        [commentsButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 2, 0,2)];
        [commentsButton setBackgroundImage:[UIImage imageNamed:@"comments.png"] forState:UIControlStateNormal];
        
        [commentsButton setTitle:NSLocalizedString(@"Menu.Comments",@"Comments") forState:UIControlStateNormal];
        commentsButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:14];
        [commentsButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [commentsButton addTarget:self action:@selector(commentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:commentsButton];
        
        leftButtonX=leftButtonX+btnWidth;
    }
    
    if([[correspondence.toolbar objectForKey:@"Transfer"] isEqualToString:@"YES"]){
        transferButton = [UIButton buttonWithType:UIButtonTypeCustom];
        transferButton.frame = CGRectMake(leftButtonX, 30, btnWidth, 90);
        [transferButton setBackgroundImage:[UIImage imageNamed:@"transfer.png"] forState:UIControlStateNormal];
        // [searchButton setImageEdgeInsets:UIEdgeInsetsMake(0, 17, 10, 0)];
        [transferButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 2, 0,2)];
        [transferButton setTitle:NSLocalizedString(@"Menu.Transfer",@"Transfer") forState:UIControlStateNormal];
        transferButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:14];
        [transferButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [transferButton addTarget:self action:@selector(transferButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:transferButton];
        
        leftButtonX=leftButtonX+btnWidth;
    }
    
    if([[correspondence.toolbar objectForKey:@"Highlight"] isEqualToString:@"YES"] || [[correspondence.toolbar objectForKey:@"Note"] isEqualToString:@"YES"]){
        annotationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        annotationButton.frame = CGRectMake(leftButtonX, 30, btnWidth, 90);
        // [annotationButton setImage:[UIImage imageNamed:@"highlight.png"] forState:UIControlStateNormal];
        [annotationButton setBackgroundImage: [UIImage imageNamed:@"Annotations.png"] forState:UIControlStateNormal];
        // [nextButton setImageEdgeInsets:UIEdgeInsetsMake(0, 17, 10, 0)];
        [annotationButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 0, 0,0)];
        [annotationButton setTitle:NSLocalizedString(@"Menu.Annotations",@"Annotations") forState:UIControlStateNormal];
        annotationButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:13];
        [annotationButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [annotationButton setTitleColor:[UIColor grayColor]forState:UIControlStateDisabled];
        [annotationButton addTarget:self action:@selector(annotationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:annotationButton];
        leftButtonX=leftButtonX+btnWidth;
    }
    if([[correspondence.toolbar objectForKey:@"Sign"] isEqualToString:@"YES"]){
        SignActionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        SignActionButton.frame = CGRectMake(leftButtonX+10, 30, btnWidth-20, 70);
      
        [SignActionButton setBackgroundImage: [UIImage imageNamed:@"Signature1.png"] forState:UIControlStateNormal];
        [SignActionButton setTitleEdgeInsets:UIEdgeInsetsMake(75, 0, 0,0)];
        [SignActionButton setTitle:NSLocalizedString(@"Menu.sign",@"Signature") forState:UIControlStateNormal];
        SignActionButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:13];
        [SignActionButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [SignActionButton setTitleColor:[UIColor grayColor]forState:UIControlStateDisabled];
        [SignActionButton addTarget:self action:@selector(SignAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:SignActionButton];
        leftButtonX=leftButtonX+btnWidth;
    }
    if(correspondence.actions.count>0 ){
        actionsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        actionsButton.frame = CGRectMake(leftButtonX, 30, btnWidth, 90);
        [actionsButton setBackgroundImage: [UIImage imageNamed:@"Actions.png"] forState:UIControlStateNormal];
        [actionsButton setTitleEdgeInsets:UIEdgeInsetsMake(55, 0, 0,0)];
        [actionsButton setTitle:NSLocalizedString(@"Menu.More",@"More...") forState:UIControlStateNormal];
        actionsButton.titleLabel.font=[UIFont fontWithName:@"Helvetica" size:13];
        [actionsButton setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        [actionsButton setTitleColor:[UIColor grayColor]forState:UIControlStateDisabled];
        [actionsButton addTarget:self action:@selector(actionsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:actionsButton];
        leftButtonX=leftButtonX+btnWidth;
    }
    
    if(correspondence.Locked==YES){
        [lockButton setBackgroundImage: [UIImage imageNamed:@"Unlock.png"] forState:UIControlStateNormal];
        [lockButton setBackgroundImage: [UIImage imageNamed:@"Lock.png"] forState:UIControlStateSelected];
        [lockButton setTitle:NSLocalizedString(@"Menu.Unlock",@"unlock") forState:UIControlStateNormal];
        
    }
    else{ [lockButton setBackgroundImage: [UIImage imageNamed:@"Lock.png"] forState:UIControlStateNormal];
        [lockButton setBackgroundImage: [UIImage imageNamed:@"Unlock.png"] forState:UIControlStateSelected];
        [lockButton setTitle:NSLocalizedString(@"Menu.Lock",@"lock") forState:UIControlStateNormal];
        
    }

}

-(void) updateTitleWithLocation:(NSString*)location withName:(NSString*)name{
    [lblTitle setText:[NSString stringWithFormat:@"LOCATION: %@   TITLE: %@",location,name]];
}

//}

@end
