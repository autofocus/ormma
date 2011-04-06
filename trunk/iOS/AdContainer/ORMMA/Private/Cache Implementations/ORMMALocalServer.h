//
//  ORMMALocalServer.h
//  ORMMA
//
//  Created by Robert Hedin on 10/15/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPServer.h"
#import "ASIHTTPRequest.h"
#import "ORMMADataAccessLayer.h"



@protocol ORMMALocalServerDelegate <NSObject>

@required

// called if a cache function fails
- (void)cacheFailed:(NSURL *)url
		  withError:(NSError *)error;

// called when a creative has been cached
- (void)cachedCreative:(NSURL *)baseURL
				 onURL:(NSURL *)url
				withId:(long)creativeId;

// called when a resource has been cached
- (void)cachedResource:(NSURL *)url
		   forCreative:(long)creativeId;

// called when a resource has been cached
- (void)cachedResourceRetired:(NSURL *)url
				  forCreative:(long)creativeId;

// called when a resource has been cached
- (void)cachedResourceRemoved:(NSURL *)url
				  forCreative:(long)creativeId;

// called to get injectable javascript
- (NSString *)javascriptForInjection;

@end



@interface ORMMALocalServer : NSObject <ASIHTTPRequestDelegate>
{
@private
	HTTPServer *m_server;
	ORMMADataAccessLayer *m_dal;

	NSString *m_htmlStub;
}
@property( nonatomic, copy, readonly ) NSString *cacheRoot;
@property( nonatomic, copy ) NSString *htmlStub;


// designated accessor for the singleton instance
+ (ORMMALocalServer *)sharedInstance;

+ (NSString *)rootDirectory;


// used to cache a specific URL
- (void)cacheURL:(NSURL *)url
	withDelegate:(id<ORMMALocalServerDelegate>)delegate;


// used to cache local HTML
- (void)cacheHTML:(NSString *)html
		  baseURL:(NSURL *)baseURL
	 withDelegate:(id<ORMMALocalServerDelegate>)delegate;


// determines the path to a specific cached url
//- (NSString *)cachePathFromURL:(NSURL *)url;


// adds a new resource to the cache for the specified creative
- (void)cacheResourceForCreative:(NSUInteger)creativeId
						   named:(NSString *)url
					withDelegate:(id<ORMMALocalServerDelegate>)delegate;

// removes a specific resource from the cache for the specified creative
- (void)removeCachedResourceForCreative:(NSUInteger)creativeId
								  named:(NSString *)url
						   withDelegate:(id<ORMMALocalServerDelegate>)delegate;

// removes all cached resources for the specified creative
- (void)removeAllCachedResourcesForCreative:(NSUInteger)creativeId
							   withDelegate:(id<ORMMALocalServerDelegate>)delegate;



// removes all currently cached resources EXCEPT those that the framework
// itself stores
+ (void)removeAllCachedResources;


- (NSString *)cachedHtmlForCreative:(long)creativeId;


@end
