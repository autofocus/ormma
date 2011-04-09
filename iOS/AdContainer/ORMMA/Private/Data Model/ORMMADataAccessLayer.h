/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

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
