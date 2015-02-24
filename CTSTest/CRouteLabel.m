//
//  CFRouteLabel.m
//  cfsPad
//
//  Created by marc balas on 09/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CRouteLabel.h"


@implementation CRouteLabel
@synthesize name,labelId,note;

-(id)initWithName:(NSString*)_name  Id:(NSString*)_id 
{
	if ((self = [super init])) {
        self.name = _name;
		self.labelId = _id;
        
        
	
	}    
    return self;
	
}

- (void) dealloc {
	self.name = nil;
	self.labelId = nil;
	
	
    
	
    }

@end
