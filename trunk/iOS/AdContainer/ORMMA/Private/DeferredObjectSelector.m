//
//  DeferredObjectSelector.m
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "DeferredObjectSelector.h"



@interface DeferredObjectSelector ()


@end




@implementation DeferredObjectSelector


#pragma mark -
#pragma mark Constants



#pragma mark -
#pragma mark Properties

@synthesize targetObject = m_targetObject;
@synthesize selector = m_selector;
@synthesize parameter = m_parameter;



#pragma mark -
#pragma mark Initializers / Memory Management


- (DeferredObjectSelector *)init
{
	if ( ( self = [super init] ) )
	{
	}
	return self;
}


- (void)dealloc
{
	[m_targetObject release], m_targetObject = nil;
	[m_parameter release], m_parameter = nil;
	[super dealloc];
}



#pragma mark -
#pragma mark Executing the Deferred Call

- (void)execute
{
	[self.targetObject performSelector:self.selector 
							withObject:self.parameter];
}


- (void)executeOnMainThread
{
	[self.targetObject performSelectorOnMainThread:self.selector
										withObject:self.parameter
									 waitUntilDone:NO];
}

@end
