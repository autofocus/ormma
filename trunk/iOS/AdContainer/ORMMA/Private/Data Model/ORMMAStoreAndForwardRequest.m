//
//  ORMMAStoreAndForwardRequest.m
//  ORMMA
//
//  Created by Robert Hedin on 10/18/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMAStoreAndForwardRequest.h"



@interface ORMMAStoreAndForwardRequest ()


@end




@implementation ORMMAStoreAndForwardRequest


#pragma mark -
#pragma mark Constants



#pragma mark -
#pragma mark Properties

@synthesize requestNumber = m_requestNumber;
@synthesize request = m_request;
@synthesize createdOn = m_createdOn;



#pragma mark -
#pragma mark Initializers / Memory Management


- (ORMMAStoreAndForwardRequest *)init
{
	if ( ( self = [super init] ) )
	{
	}
	return self;
}


- (void)dealloc
{
	[m_request release], m_request = nil;
	[m_createdOn release], m_createdOn = nil;
	[super dealloc];
}

@end
