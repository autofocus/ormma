//
//  ORMMADataAccessLayer.h
//  ORMMA
//
//  Created by Robert Hedin on 10/15/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "ORMMAStoreAndForwardRequest.h"


@interface ORMMADataAccessLayer : NSObject 
{
@private
	FMDatabase *m_database;
	NSBundle *m_ormmaBundle;
}

// designated accessor for the singleton instance
+ (ORMMADataAccessLayer *)sharedInstance;


// for managing the cache
- (void)removeAllCreatives;
- (void)cacheCreative:(long)creativeId
			   forURL:(NSURL *)url;
- (void)creativeAccessed:(long)creativeId;
- (void)removeCreative:(long)creativeId;
- (void)incrementCacheUsageForCreative:(long)creativeId
									by:(unsigned long long)bytes;
- (void)decrementCacheUsageForCreative:(long)creativeId
									by:(unsigned long long)bytes;
- (void)truncateCacheUsageForCreative:(long)creativeId;


// for store and forward requests
- (void)storeRequest:(NSString *)request;
- (ORMMAStoreAndForwardRequest *)getNextStoreAndForwardRequest;
- (void)removeStoreAndForwardRequestWithRequestNumber:(NSNumber *)requestNumber;

@end
