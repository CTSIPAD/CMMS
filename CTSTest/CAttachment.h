//
//  CAttachment.h
//  CTSTest
//
//  Created by DNA on 12/12/13.
//  Copyright (c) 2013 LBI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CAttachment : NSObject<NSURLConnectionDelegate>

@property (nonatomic, retain) NSString* location;
@property (nonatomic, retain) NSString* docId;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* url;
@property (nonatomic, retain) NSString* thumbnailBase64;
@property (nonatomic, retain) NSMutableArray* annotations;
@property (nonatomic, retain)  NSString *tempPdfLocation;


-(id) initWithTitle:(NSString*)title docId:(NSString*)did url:(NSString*)url  thumbnailBase64:(NSString*)thumbnailBase64 location:(NSString*)folderName;
-(NSString *)saveInCacheinDirectory:(NSString*)dirName fromSharepoint:(BOOL)isSharePoint;
@end
