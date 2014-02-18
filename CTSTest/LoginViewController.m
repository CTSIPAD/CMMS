//
//  ViewController.m
//  CTSTest
//
//  Created by DNA on 12/11/13.
//  Copyright (c) 2013 LBI. All rights reserved.
//

#import "LoginViewController.h"
#import "MainMenuViewController.h"
#import "HomeViewController.h"
#import "StringEncryption.h"
#import "CParser.h"
#import "CUser.h"
#import "CMenu.h"
#import "CCorrespondence.h"
#import "CAttachment.h"

#define TAG_OK 1
#define TAG_NO 2
@interface LoginViewController ()

@end

@implementation LoginViewController
{
    BOOL isChecking;
    AppDelegate *appDelegate;
    UILabel *lblTitle;
    UILabel *lblLogin;
    UILabel *lblPass;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    lblTitle=[[UILabel alloc]initWithFrame:CGRectMake(340,40,400,150)];
    lblTitle.textColor = [UIColor whiteColor];
    lblTitle.text =@"EverSuite For iPad";
    
    lblTitle.backgroundColor = [UIColor clearColor];
    lblTitle.font =[UIFont fontWithName:@"Helvetica" size:40.0f];
   // [self.view addSubview:lblTitle];
    
    lblLogin=[[UILabel alloc]initWithFrame:CGRectMake(300,250,200,40)];
    lblLogin.textColor = [UIColor whiteColor];
    lblLogin.text =NSLocalizedString(@"Login",@"Login");
    
    lblLogin.backgroundColor = [UIColor clearColor];
    lblLogin.font =[UIFont fontWithName:@"Helvetica" size:24.0f];
    //[self.view addSubview:lblLogin];
    
    txtUsername=[[UITextField alloc]initWithFrame:CGRectMake(300, 290, 200, 45)];
    txtUsername.layer.borderWidth=2;
    txtUsername.backgroundColor=[UIColor whiteColor];
    txtUsername.layer.borderColor=[[UIColor grayColor] CGColor];
    txtUsername.layer.cornerRadius=10;
    txtUsername.clipsToBounds=YES;
    txtUsername.delegate = self;
    txtUsername.returnKeyType = UIReturnKeyGo;
     txtUsername.leftViewMode = UITextFieldViewModeAlways;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 35)];
     txtUsername.leftView= paddingView;
   
    [self.view addSubview:txtUsername];
    
    lblPass=[[UILabel alloc]initWithFrame:CGRectMake(520,250,200,40)];
    lblPass.textColor = [UIColor whiteColor];
    lblPass.text =@"Password";
    
    lblPass.backgroundColor = [UIColor clearColor];
    lblPass.font =[UIFont fontWithName:@"Helvetica" size:24.0f];
   // [self.view addSubview:lblPass];
    
    txtPassword=[[UITextField alloc]initWithFrame:CGRectMake(520, 290, 200, 45)];
    txtPassword.layer.borderWidth=2;
    txtPassword.backgroundColor=[UIColor whiteColor];
    txtPassword.layer.borderColor=[[UIColor grayColor] CGColor];
    txtPassword.layer.cornerRadius=10;
    txtPassword.clipsToBounds=YES;
    txtPassword.delegate = self;
    txtPassword.secureTextEntry=YES;
    txtPassword.returnKeyType = UIReturnKeyGo;
    txtPassword.leftViewMode = UITextFieldViewModeAlways;
    UIView *paddingView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 35)];
     txtPassword.leftView= paddingView2;
    [self.view addSubview:txtPassword];

    btnLogin=[[UIButton alloc]initWithFrame:CGRectMake(440, 360, 150, 40)];
    [btnLogin setTitle:NSLocalizedString(@"Login",@"Login") forState:UIControlStateNormal];
    btnLogin.backgroundColor=[UIColor colorWithRed:37/255.0f green:96/255.0f blue:172/255.0f alpha:1.0];
    [btnLogin setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnLogin.layer.borderColor=[[UIColor grayColor] CGColor];
    btnLogin.layer.cornerRadius=10;
    btnLogin.clipsToBounds=YES;
    [btnLogin.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:24]];
      [btnLogin addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnLogin];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self adjustControls:orientation];
    [self getLicense];
    

}
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration{
    [self adjustControls:interfaceOrientation];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    
	if(interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"loginPortrait.jpg"]];
        
        
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"loginLandscape.jpg"]];
        
    }
	
}


-(void)getLicense{
    isChecking=YES;
   // NSString* language=[[[NSBundle mainBundle] preferredLocalizations]objectAtIndex:0];
   	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *active = [prefs stringForKey:@"Activated"];
    NSString *trialDate = [prefs stringForKey:@"trialStartDate"];
    NSString *trialEndDate = [prefs stringForKey:@"trialEndDate"];
    NSString *licenseKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"licenseKey_preference"];
    if([licenseKey length]>0)
    {
        if ([active isEqualToString:@"Active"]) {
            [btnLogin addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            NSString *licenseKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"licenseKey_preference"];
            if([licenseKey isEqualToString:@"MNADNAMNADNA"]){
                [btnLogin addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
            }
            else
            {
                [self validateKey];
                
            }
        }
    }
    else if ([licenseKey length]==0 && [active length]==0 && [trialDate length]==0) {
    
        alertLicense=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Login.Licence",@"License Key") message:NSLocalizedString(@"Alert.LicenceAlert",@"License Key unavailable,please provide a key or continue as trial") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") otherButtonTitles:NSLocalizedString(@"Continue",@"Continue"),nil];
        
        alertLicense.tag=TAG_OK;
        //[alertLicense addTextFieldWithValue:@""label:@"License"];
        [alertLicense show];
        // Customise name field
        
    }
    else if([trialDate length]>0 && [trialEndDate length]>0)
    {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd hh:mm:ss a"];
        NSDate *myDate = [df dateFromString: trialEndDate];
        
        NSTimeInterval dateDiff=[myDate timeIntervalSinceNow];
        if (dateDiff<0) {
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Alert",@"Alert") message:NSLocalizedString(@"Alert.Trial" ,@"Trial expired please insert license key in settings menu") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") otherButtonTitles: nil  ] ;
            [alert show];
        }
        else
        {
             [btnLogin addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
        }
        
    }
    
    else{
         [btnLogin addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        //cancel clicked ...do your action
        if(alertView.tag==TAG_NO)
        {
            [alertLicense show];
        }
    }
    else if (buttonIndex == 1)
    {
        if(alertView.tag==TAG_OK)
        {
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSDate *dt=[NSDate date];
            int daysToAdd = 30;  // or 60 :-)
            NSDate *endDate = [dt dateByAddingTimeInterval:60*60*24*daysToAdd];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd hh:mm:ss a"];
            
            
            
            NSString *stringFromDate = [formatter stringFromDate:dt];
            NSString *stringEndDate= [formatter stringFromDate:endDate];
            [prefs setObject:stringFromDate forKey:@"trialStartDate"];
            [prefs setObject:stringEndDate forKey:@"trialEndDate"];
            [prefs setObject:@"Trial" forKey:@"Activated"];
            //if ([self checkLicense:licenseKey]) {
            // [prefs setObject:licenseKey forKey:@"LicenseKey"];
            [prefs synchronize];
            [btnLogin addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
            
            
            
            [super viewDidLoad];
                   }
        else
        {
            [alertLicense show];
        }
       
        
    }
}

-(void)validateKey{
    
    recordResults=FALSE;
    CFUUIDRef UIID = CFUUIDCreate(NULL);
    CFStringRef UIIDString = (CFUUIDCreateString(NULL, UIID));
    NSString *deviceId = [NSString stringWithFormat:@"%@",UIIDString];
    //NSString *deviceId = [[UIDevice currentDevice] uniqueIdentifier];
  	NSString *licenseKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"licenseKey_preference"];
   
    NSString *companyName = [[NSUserDefaults standardUserDefaults] stringForKey:@"company_preference"];

    
    NSString *soapMessage=  [NSString stringWithFormat:
                             
                             @" <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                             "  <soap:Body>"
                             " <iValidate xmlns=\"http://tempuri.org/\">"
                             " <encrSerialId>%@</encrSerialId>"
                             " <encrLicenseKey>%@</encrLicenseKey>"
                             " <encrCompany>%@</encrCompany>"
                             " </iValidate>"
                             " </soap:Body>"
                             " </soap:Envelope>",[self EncryptWord:deviceId],[self EncryptWord:licenseKey],[self EncryptWord:companyName]];
  
    NSURL *url = [NSURL URLWithString:@"http://www.eversuite.net/EverSuiteValidation.asmx"];
    //  NSURL *url = [NSURL URLWithString:@"http://192.168.30.209:8081/esvalidate/EverSuiteValidation.asmx"];
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url];
    NSString *msgLength = [NSString stringWithFormat:@"%d", [soapMessage length]];
    
    [theRequest addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [theRequest addValue: @"http://tempuri.org/iValidate" forHTTPHeaderField:@"SOAPAction"];
    [theRequest addValue: msgLength forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setHTTPBody: [soapMessage dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if( theConnection )
    {
        conWebData = [NSMutableData data];
        NSLog(@"%@",conWebData);
    }
    else
    {
        NSLog(@"theConnection is NULL");
    }
    
}

-(NSString*)EncryptWord:(NSString*) word{

    
    NSString * _key = @"LebanonSurface10452";
	
	StringEncryption *crypto = [[StringEncryption alloc] init];
	NSData *_secretData = [word dataUsingEncoding:NSUTF8StringEncoding];
	CCOptions padding = kCCOptionPKCS7Padding;
	NSData *encryptedData = [crypto encrypt:_secretData key:[_key dataUsingEncoding:NSUTF8StringEncoding] padding:&padding];
	
    return [encryptedData base64EncodingWithLineLength:0];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self connect];
    //[textField resignFirstResponder];
    return YES;
}

-(void)connect{
    @try{
        
  
    NSString *username = txtUsername.text;
    NSString *password = txtPassword.text;
    if([username isEqual:@""] == FALSE && [password isEqual:@""] == FALSE){
        
        NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
        
        NSString * _key = @"EverTeamYears202020";
        
        StringEncryption *crypto = [[StringEncryption alloc] init];
        NSData *_secretData = [password dataUsingEncoding:NSUTF8StringEncoding];
        CCOptions padding = kCCOptionPKCS7Padding;
        NSData *encryptedData = [crypto encrypt:_secretData key:[_key dataUsingEncoding:NSUTF8StringEncoding] padding:&padding];
       
        NSString* url = [NSString stringWithFormat:@"http://%@?action=login&usercode=%@&password=%@",serverUrl,username,[encryptedData base64EncodingWithLineLength:0]];
        NSURL *xmlUrl = [NSURL URLWithString:url];
        
        NSMutableURLRequest* request=[[NSMutableURLRequest alloc]initWithURL:xmlUrl];
        [request addValue:username forHTTPHeaderField:@"usercode"];
        [request addValue:password forHTTPHeaderField:@"password"];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if(connection)
        {
          //  NSMutableData* receivedData=[NSMutableData data];
                [self performSelectorOnMainThread:@selector(increaseProgress) withObject:nil waitUntilDone:YES];
          [connection start];
        }
        else
        {
            [self ShowMessage:NSLocalizedString(@"Alert.Connection",@"Connection not found")];
        }

        
        

        
            }
    else {
        [self ShowMessage:NSLocalizedString(@"Alert.EmptyUser",@"Username or password is Empty")];
        
    }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"LoginViewController" function:@"Connect" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    [self performSelector:@selector(performConnecting:) withObject:data];
    
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
     [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
     [self ShowMessage:NSLocalizedString(@"Alert.Connection",@"Connection not found")];
}

-(void)performConnecting:(NSData *)data{
    
    @try{
    appDelegate=(AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.ipadLanguage=[[[NSBundle mainBundle] preferredLocalizations]objectAtIndex:0];
    NSString *serverUrl = [[NSUserDefaults standardUserDefaults] stringForKey:@"url_preference"];
    BOOL isOfflineMode = [[[NSUserDefaults standardUserDefaults] stringForKey:@"offline_mode"] boolValue];
    
    NSString *validationResultUser=[CParser ValidateWithData:data];
    CUser * user;
    if(![validationResultUser isEqualToString:@"OK"])
    {
        [self ShowMessage:validationResultUser];
        
    }
    else {
        user = [CParser loadUserWithData:data];
        user.loginName=txtUsername.text;
        appDelegate.userLanguage=user.language;
        if([user.serviceType.lowercaseString isEqualToString:@"sharepoint"])
            appDelegate.isSharepoint=YES;

        if(user.menu.count>0){
        
            
            NSString *inboxIds=@"";
            if(isOfflineMode){
                for(CMenu *menu in user.menu){
                    inboxIds=[NSString stringWithFormat:@"%@%d,",inboxIds,menu.menuId];
                }
            }else inboxIds=[NSString stringWithFormat:@"%d",((CMenu*)user.menu[0]).menuId];
            
            
            
            NSString* homeUrl = [NSString stringWithFormat:@"http://%@?action=GetCorrespondences&token=%@&inboxIds=%@",serverUrl,user.token,inboxIds];
            NSURL *xmlUrl = [NSURL URLWithString:homeUrl];
            NSData *homeXmlData = [[NSMutableData alloc] initWithContentsOfURL:xmlUrl];
            
            NSString *validationResultHome=[CParser ValidateWithData:homeXmlData];
            if(![validationResultHome isEqualToString:@"OK"]){
                [self ShowMessage:validationResultHome];
            }
            else{
                
                
                NSMutableDictionary *correspondences=[CParser loadCorrespondencesWithData:homeXmlData];
                for (CMenu* menu in user.menu)
                {
                    menu.correspondenceList=[correspondences objectForKey:[NSString stringWithFormat:@"%d",menu.menuId]];
                    
                }
                // ((CMenu*)user.menu[0]).correspondenceList=correspondences;
                // user.homeXmlData=homeXmlData;
                appDelegate.user=user;
                
                if(isOfflineMode)
                    [self SaveDocsBaskets:user ];
                
                MainMenuViewController *root = [[MainMenuViewController alloc] init];
                UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
                [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
                [flowLayout setMinimumInteritemSpacing:5.0f];
                [flowLayout setMinimumLineSpacing:5.0f];
                HomeViewController *detail = [[HomeViewController alloc]initWithCollectionViewLayout:flowLayout];
                appDelegate.menuSelectedItem=0;
                
                UINavigationController *rootNavigation = [[UINavigationController alloc] initWithRootViewController:root];
                
                UINavigationController *detailNavigation = [[UINavigationController alloc] initWithRootViewController:detail];
                
                appDelegate.splitViewController.viewControllers = [NSArray arrayWithObjects:rootNavigation, detailNavigation, nil];
                appDelegate.splitViewController.delegate = detail;
                
                
                [appDelegate.window setRootViewController:(UIViewController*)appDelegate.splitViewController];
                
                [appDelegate.window makeKeyAndVisible];
            }
        }
    }
    }
    @catch (NSException *ex) {
        [FileManager appendToLogView:@"LoginViewController" function:@"performConnecting" ExceptionTitle:[ex name] exceptionReason:[ex reason]];
    }
}

-(void)SaveDocsBaskets:(CUser*) user
{
    for(CMenu* inbox in user.menu )
	{
        
		if (inbox.correspondenceList.count>0)
        {
            for(CCorrespondence* correspondence in inbox.correspondenceList)
            {
                if (correspondence.attachmentsList.count>0) {
                    for(CAttachment* doc in correspondence.attachmentsList)
                    {
                        [self saveDocInCache:doc inDirectory:correspondence.Id];
                    }
                }
                
               // NSLog(@"task name : %@ id : %@ ",task.name,task.tid);
            }
        }
				
		
	}
}
-(void)saveDocInCache:(CAttachment*)firstDoc inDirectory:(NSString*)dirName
{
	[firstDoc saveInCacheinDirectory:dirName fromSharepoint:appDelegate.isSharepoint];
	
}

-(void)adjustControls:(UIInterfaceOrientation)interfaceOrientation{
    if(interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        
         self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"loginPortrait.jpg"]];
        
        //lblTitle.frame=CGRectMake(240,40,400,150);
       // lblLogin.frame=CGRectMake(200,250,200,40);
        txtUsername.frame=CGRectMake(220, 410, 350, 40);
       // lblPass.frame=CGRectMake(420,250,200,40);
        txtPassword.frame=CGRectMake(220, 475, 350, 40);
        btnLogin.frame=CGRectMake(180, 550, 120, 40);
        
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight){
         self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"loginLandscape.jpg"]];
        //lblTitle.frame=CGRectMake(340,40,400,150);
       //lblLogin.frame=CGRectMake(300,250,200,40);
        txtUsername.frame=CGRectMake(350, 280, 350, 40);
      //  lblPass.frame=CGRectMake(520,250,200,40);
        txtPassword.frame=CGRectMake(350, 340, 350, 40);
        btnLogin.frame=CGRectMake(300, 420, 120, 40);
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

- (void)increaseProgress{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Progress.Connecting",@"Connecting ...") maskType:SVProgressHUDMaskTypeBlack];
}

- (void)dismiss {
	[SVProgressHUD dismiss];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
	return YES;
}

@end
