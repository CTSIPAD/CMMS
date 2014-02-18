
#import "CFPendingAction.h"


@implementation CFPendingAction
@synthesize actionUrl,hasBeenProcessed;

-(id) initWithActionUrl:(NSString*)_actionUrl
{
	
    if ((self = [super init])) {
		
		self.actionUrl = _actionUrl;
		self.hasBeenProcessed = NO;
    }    
    return self;
	
}


@end
