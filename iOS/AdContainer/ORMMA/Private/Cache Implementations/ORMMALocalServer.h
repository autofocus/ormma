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



@protocol ORMMALocalServerDelegate

@required

- (void)cacheFailed:(NSURL *)baseURL
		  withError:(NSError *)error;

- (void)cachedBaseURL:(NSURL *)baseURL
				onURL:(NSURL *)url
			   withId:(NSUInteger)creativeId;

@end



@interface ORMMALocalServer : NSObject <ASIHTTPRequestDelegate>
{
@private
	HTTPServer *m_server;
	ORMMADataAccessLayer *m_dal;
}
@property( nonatomic, copy, readonly ) NSString *cacheRoot;


// designated accessor for the singleton instance
+ (ORMMALocalServer *)sharedInstance;


// used to cache a specific URL
- (void)cacheURL:(NSURL *)url
	withDelegate:(id<ORMMALocalServerDelegate>)delegate;


// used to cache local HTML
- (void)cacheHTML:(NSString *)html
		  baseURL:(NSURL *)baseURL
	 withDelegate:(id<ORMMALocalServerDelegate>)delegate;


- (NSString *)cachePathFromURL:(NSURL *)url;


+ (void)removeAllCachedResources;


@end
