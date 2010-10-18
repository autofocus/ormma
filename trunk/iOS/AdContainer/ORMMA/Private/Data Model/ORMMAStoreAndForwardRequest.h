//
//  ORMMAStoreAndForwardRequest.h
//  ORMMA
//
//  Created by Robert Hedin on 10/18/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ORMMAStoreAndForwardRequest : NSObject 
{
@private
	long m_requestNumber;
	NSString *m_request;
	NSDate *m_createdOn;
}
@property( nonatomic, assign ) long requestNumber;
@property( nonatomic, copy ) NSString *request;
@property( nonatomic, copy ) NSDate *createdOn;

@end
