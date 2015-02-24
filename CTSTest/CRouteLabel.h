//
//  CFRouteLabel.h
//  cfsPad
//
//  Created by marc balas on 09/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CRouteLabel : NSObject {

	NSString* name;
	NSString* labelId;
    NSString* note;
	
}
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* labelId;
@property (nonatomic, retain) NSString* note;


-(id)initWithName:(NSString*)_name  Id:(NSString*)_id;

@end
