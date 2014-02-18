//
//  CFDestination.m
//  cfsPad
//
//  Created by marc balas on 09/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CDestination.h"


@implementation CDestination

@synthesize name,rid,type;

-(id)initWithName:(NSString*)_name  Id:(NSString*)_rid  Type:(NSString*)_type
{
	if ((self = [super init])) {
        self.name = _name;
		self.rid = _rid;
        self.type = _type;
	}    
    return self;
	
}

- (void) dealloc {
	self.name = nil;
	self.rid = nil;
	self.type = nil;
		
	
    
}
@end
