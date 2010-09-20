//
//  DeferredObjectSelector.h
//  RichMediaAds
//
//  Created by Robert Hedin on 9/7/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DeferredObjectSelector : NSObject 
{
@private
	id m_targetObject;
	SEL m_selector;
	id m_parameter;
}
@property( nonatomic, retain ) id targetObject;
@property( nonatomic, assign ) SEL selector;
@property( nonatomic, retain ) id parameter;


// executes the deferred call on the same thread
- (void)execute;

// executes the deferred call, but forces it to the main thread if necessary
- (void)executeOnMainThread;

@end
