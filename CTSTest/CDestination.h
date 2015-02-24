//
//  CFDestination.h
//  cfsPad
//
//  Created by marc balas on 09/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
/*

enum CFAnnotType {
    CFAnnotTypeUnderline = 1,
	CFAnnotTypeLine,
    CFAnnotTypeHighlight,
    CFAnnotTypeStroke,
    CFAnnotTypeInk,
    CFAnnotTypeNote,
	CFAnnotTypeOther
};
typedef enum CFAnnotType CFAnnotType;
*/


@interface CDestination : NSObject {

	
	//by me, can be shown and modified
	
	NSString* name;
	NSString* rid;
	
	NSString* type;
	
	
	
	
	
}
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* rid;
@property (nonatomic, retain) NSString* type;


-(id)initWithName:(NSString*)_name  Id:(NSString*)_rid  Type:(NSString*)_type;



@end
