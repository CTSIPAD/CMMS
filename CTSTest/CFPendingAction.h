

#import <Foundation/Foundation.h>

#import "CCorrespondence.h"


@interface CFPendingAction : NSObject {


	NSString* actionUrl;
    BOOL hasBeenProcessed;
	
}

@property (nonatomic, retain) NSString *actionUrl;
@property (nonatomic,readwrite) BOOL hasBeenProcessed;



-(id) initWithActionUrl:(NSString*)actionUrl;


@end
