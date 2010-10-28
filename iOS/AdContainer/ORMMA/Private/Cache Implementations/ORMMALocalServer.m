//
//  ORMMALocalServer.m
//  ORMMA
//
//  Created by Robert Hedin on 10/15/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMALocalServer.h"



@interface ORMMALocalServer ()

- (NSString *)resourcePathForCreative:(NSUInteger)creativeId
							   forURL:(NSURL *)url;
+ (unsigned long long)removeObjectsInDirectory:(NSString *)directory
								  includeFiles:(BOOL)files;
+ (NSString *)rootDirectory;

@end




@implementation ORMMALocalServer


#pragma mark -
#pragma mark Constants

NSString * const kORMMALocalServerWebRoot = @"ormma-web-root";
NSString * const kORMMALocalServerDelegateKey = @"delegate";
NSString * const kORMMALocalServerTypeKey = @"type";
NSString * const kORMMALocalServerPathKey = @"path";
NSString * const kORMMALocalServerCreativeIdKey = @"id";

NSString * const kORMMALocalServerCreativeType = @"creative";
NSString * const kORMMALocalServerResourceType = @"resource";



#pragma mark -
#pragma mark Properties

@dynamic cacheRoot;



#pragma mark -
#pragma mark Initializers / Memory Management


+ (ORMMALocalServer *)sharedInstance
{
	static ORMMALocalServer *sharedInstance = nil;

    @synchronized( self )
    {
        if ( sharedInstance == nil )
		{
			sharedInstance = [[ORMMALocalServer alloc] init];
		}
    }
    return sharedInstance;
}


- (ORMMALocalServer *)init
{
	if ( ( self = [super init] ) )
	{
		// Setup Access to the database
		m_dal = [ORMMADataAccessLayer sharedInstance];
		
		// setup our Internal HTTP Server
		NSError *error = nil;
		m_server = [[HTTPServer alloc] init];
		NSURL *url = [NSURL fileURLWithPath:[self cacheRoot]];
		[m_server setDocumentRoot:url];
		[m_server start:&error];
		
		// make sure the root path exists
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm createDirectoryAtPath:self.cacheRoot 
	  withIntermediateDirectories:YES 
					   attributes:nil 
							error:NULL];
		
	}
	return self;
}


- (void)dealloc
{
	// shutdown our server
	[m_server stop];
	[m_server release], m_server = nil;
	[super dealloc];
}



#pragma mark -
#pragma mark Properties

- (NSString *)cacheRoot
{
	return [ORMMALocalServer rootDirectory];
}


+ (NSString *)rootDirectory
{
	// determine the root where our cache will be stored
    NSArray *systemPaths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES ); 
    NSString *basePath = [systemPaths objectAtIndex:0]; 
	
	// add the root
	NSString *path = [basePath stringByAppendingPathComponent:kORMMALocalServerWebRoot];
	
	return path;
}



#pragma mark -
#pragma mark Cache Management

+ (void)removeAllCachedResources;
{
	// we've been asked to remove everything we've cached (usually for error
	// recovery) so start walking our cache directory and start to recursively
	// remove every file we find.
	//
	// NOTE: we're going to leave any files in the *root* directory as user
	//       code cannot cache files to the root.
	
	BOOL isDirectory;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *list = [fm contentsOfDirectoryAtPath:[ORMMALocalServer rootDirectory] 
											error:NULL];
	for ( NSString *path in list )
	{
		if ( [fm fileExistsAtPath:path isDirectory:&isDirectory] )
		{
			// the object exists, do we care?
			if ( isDirectory )
			{
				// it is a directory, process it
				[self removeObjectsInDirectory:path
								  includeFiles:YES];
				
				// we've processed the directory, remove it
				[fm removeItemAtPath:path
							   error:NULL];
			}
		}
	}
	
	// now remove all cache entries from our database
	ORMMADataAccessLayer *dal = [ORMMADataAccessLayer sharedInstance];
	[dal removeAllCreatives];
	
}


+ (unsigned long long)removeObjectsInDirectory:(NSString *)directory
								  includeFiles:(BOOL)files
{
	unsigned long long size = 0;
	BOOL isDirectory;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *list = [fm contentsOfDirectoryAtPath:directory 
											error:NULL];
	for ( NSString *path in list )
	{
		if ( [fm fileExistsAtPath:path isDirectory:&isDirectory] )
		{
			// the object exists
			if ( isDirectory )
			{
				// it is a directory, process it
				size += [self removeObjectsInDirectory:path
										  includeFiles:YES];

				// now remove the directory
				[fm removeItemAtPath:path
							   error:NULL];
			}
			else
			{
				// if it's a file, make sure we care
				if ( files )
				{
					// let's get the size
					NSDictionary *attr = [fm attributesOfItemAtPath:path
					error:NULL];
					size += [attr fileSize];
					
					// now remove the file
					[fm removeItemAtPath:path
					error:NULL];
					}
			}
			
		}
	}
	return size;
}


- (void)cacheURL:(NSURL *)url
	withDelegate:(id<ORMMALocalServerDelegate>)delegate;
{
	// setup our dictionary for the callback
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:delegate, kORMMALocalServerDelegateKey,
																		kORMMALocalServerTypeKey, kORMMALocalServerCreativeType,
																		nil];
	
	// this should retrieve the data from the specified URL
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	request.delegate = self;
	request.userInfo = userInfo;
	[request startAsynchronous];
}


- (void)cacheHTML:(NSString *)html
		  baseURL:(NSURL *)baseURL
	 withDelegate:(id<ORMMALocalServerDelegate>)delegate;
{
	NSLog( @"Caching HTML" );

	// determine the hash for this creative
	NSUInteger creativeId = [html hash];
	NSString *path = [self.cacheRoot stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu", creativeId]];
	NSString *fqpn = [path stringByAppendingPathComponent:@"index.html"];
	
	// see if we already have this creative cached
	NSFileManager *fm = [NSFileManager defaultManager];
	if ( ![fm fileExistsAtPath:fqpn] )
	{
		// we don't have it yet
		// make sure the directory exists
		[fm createDirectoryAtPath:path 
	  withIntermediateDirectories:YES 
					   attributes:nil 
							error:NULL];
	}

	// update our copy on disk
	NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
	[data writeToFile:fqpn
		   atomically:YES];
	
	// update our database
	NSLog( @"Update cache database" );
	[m_dal cacheCreative:creativeId 
				  forURL:baseURL];
	
	// Now, notify the delegate that we've saved the resource
	NSLog( @"Notify delegate that object was cached" );
	NSString *urlString = [NSString stringWithFormat:@"http://localhost:%i/%lu/index.html", [m_server port], 
																						   creativeId];
	NSURL *url = [NSURL URLWithString:urlString];
	[delegate cachedCreative:baseURL
					   onURL:url
					  withId:creativeId];
	NSLog( @"Object caching complete" );
}



#pragma mark -
#pragma mark Caching Resources for a Creative

- (void)cacheResourceForCreative:(NSUInteger)creativeId
						   named:(NSString *)urlString
					withDelegate:(id<ORMMALocalServerDelegate>)delegate
{
	// determine the path to the resource
	NSURL *url = [NSURL URLWithString:urlString];
	NSString *resourcePath = [self resourcePathForCreative:creativeId
													forURL:url];
	
	// setup our dictionary for the callback
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:delegate, kORMMALocalServerDelegateKey,
																		kORMMALocalServerTypeKey, kORMMALocalServerCreativeType,
																		kORMMALocalServerPathKey, resourcePath,
																		kORMMALocalServerCreativeIdKey, [NSNumber numberWithLong:creativeId],
																		nil];
	
	// this should retrieve the data from the specified URL
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	request.delegate = self;
	request.userInfo = userInfo;
	[request startAsynchronous];
}


- (void)removeCachedResourceForCreative:(NSUInteger)creativeId
								  named:(NSString *)url
						   withDelegate:(id<ORMMALocalServerDelegate>)delegate
{
	// build the path to the resource
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *path = [self resourcePathForCreative:creativeId
											forURL:[NSURL URLWithString:url]];
	NSDictionary *attr = [fm attributesOfItemAtPath:path 
											  error:NULL];
	[fm removeItemAtPath:path
				   error:NULL];	
	
	[m_dal decrementCacheUsageForCreative:creativeId
									   by:attr.fileSize];
}


- (void)removeAllCachedResourcesForCreative:(NSUInteger)creativeId
							   withDelegate:(id<ORMMALocalServerDelegate>)delegate
{
	// build the path to the creatives directory
	NSString *path = [self.cacheRoot stringByAppendingFormat:@"/%lu", creativeId];
	[ORMMALocalServer removeObjectsInDirectory:path
								  includeFiles:NO];
	
	
	// Now update our database
	[m_dal truncateCacheUsageForCreative:creativeId];
}



#pragma mark -
#pragma mark ASI HTTP Request Delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	// determine the base URL to use for storage
	NSURL *baseURL = [request originalURL];

	// determine the type and get the delegate
	NSString *type = (NSString *)[request.userInfo objectForKey:kORMMALocalServerDelegateKey];
	id<ORMMALocalServerDelegate> d = (id<ORMMALocalServerDelegate>)[request.userInfo objectForKey:kORMMALocalServerDelegateKey];
	
	// now process the response based on the type
	if ( [kORMMALocalServerCreativeType isEqualToString:type] )
	{
		// dealing with a full creative
		// get the HTML
		NSString *html = [request responseString];
		
		//store the retrieved data
		[self cacheHTML:html
				baseURL:baseURL
		   withDelegate:d];
	}
	else if ( [kORMMALocalServerResourceType isEqualToString:type] )
	{
		// we're caching a resource
		// get the raw data
		NSData *data = [request responseData];
		
		// get the path to store the resource
		NSString *path = (NSString *)[request.userInfo objectForKey:kORMMALocalServerPathKey];

		// now store the resource
		if ( [data writeToFile:path
					atomically:YES] )
		{
			NSNumber *n = (NSNumber *)[request.userInfo objectForKey:kORMMALocalServerCreativeIdKey];
			long creativeId = [n longValue];
			
			// update our cache
			[m_dal incrementCacheUsageForCreative:creativeId
											   by:[data length]];
			
			// write was successful
			[d cachedResource:baseURL
				  forCreative:creativeId];
		}
		else
		{
			
			// write failed
			[d cacheFailed:baseURL
				 withError:NULL];
		}
	}
	else
	{
		[NSException raise:@"Invalid Value Exception"
					format:@"Unrecognized Type for request: %@", type];
	}
	
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
	// get the error
	NSError *error = request.error;
	
	// notify the delegate that the request failed
	id<ORMMALocalServerDelegate> delegate = (id<ORMMALocalServerDelegate>)[request.userInfo objectForKey:kORMMALocalServerDelegateKey];
	[delegate cacheFailed:[request originalURL]
				withError:error];
}



#pragma mark -
#pragma mark Utility

// our resource path is: host + path1 + ... + pathN + resource
- (NSString *)resourcePathForCreative:(NSUInteger)creativeId
							   forURL:(NSURL *)url
{
	// start with the host
	NSMutableString *path = [NSMutableString stringWithCapacity:500];
	[path appendFormat:@"%@/%lu/%@", self.cacheRoot, creativeId, [url host]];
	
	// add all but the actual resource
	NSArray *pathComponents = [url pathComponents];
	for ( NSInteger index = 0; index < ( pathComponents.count - 2 ); index++ )
	{
		NSString *component = [pathComponents objectAtIndex:index];
		[path appendFormat:@"/%@", component];
	}
	
	// now make sure the path exists
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm createDirectoryAtPath:path 
  withIntermediateDirectories:YES 
				   attributes:nil 
						error:NULL];

	// now finish off the path
	[path appendFormat:@"/%@", [url lastPathComponent]];
	return path;
}
//
//
//// our cache path will end up being
//// ROOT + host + path1 + ... + pathN + resource
//- (NSString *)cachePathFromURL:(NSURL *)url
//{
//	// add the root
//	NSString *path = self.cacheRoot;
//	
//	// add the resource path
//	NSString *rp = [self resourcePathFromBaseURL:url];
//	
//	path = [path stringByAppendingPathComponent:rp];
//	
//	// done
//	return path;
//}


@end
