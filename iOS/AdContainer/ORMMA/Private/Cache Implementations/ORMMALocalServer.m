//
//  ORMMALocalServer.m
//  ORMMA
//
//  Created by Robert Hedin on 10/15/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMALocalServer.h"



@interface ORMMALocalServer ()

- (NSString *)resourcePathFromBaseURL:(NSURL *)url;
+ (void)removeObjectsInDirectory:(NSString *)directory;
+ (NSString *)rootDirectory;

@end




@implementation ORMMALocalServer


#pragma mark -
#pragma mark Constants

NSString * const kORMMALocalServerWebRoot = @"ormma-web-root";
NSString * const kORMMALocalServerDelegateKey = @"delegate";



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
				[self removeObjectsInDirectory:path];
				
				// we've processed the directory, remove it
				[fm removeItemAtPath:path
							   error:NULL];
			}
		}
	}
	
}


+ (void)removeObjectsInDirectory:(NSString *)directory
{
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
				[self removeObjectsInDirectory:path];
			}
			
			// now remove the file/directory
			[fm removeItemAtPath:path
						  error:NULL];
		}
	}
}


- (void)cacheURL:(NSURL *)url
	withDelegate:(id<ORMMALocalServerDelegate>)delegate;
{
	// setup our dictionary for the callback
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:delegate, kORMMALocalServerDelegateKey,
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
	// determine the hash for this creative
	NSUInteger creativeId = [html hash];
	NSString *path = [self.cacheRoot stringByAppendingPathComponent:[NSString stringWithFormat:@"%u", creativeId]];
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
		
		// write the file to disk
		NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
		[data writeToFile:fqpn
			   atomically:YES];
	}
	
	// Now, notify the delegate that we've saved the resource
	NSString *urlString = [NSString stringWithFormat:@"http://localhost:%i/%u/index.html", [m_server port], 
																						   creativeId];
	NSURL *url = [NSURL URLWithString:urlString];
	[delegate cachedBaseURL:baseURL
					 onURL:url
					 withId:creativeId];
}


#pragma mark -
#pragma mark ASI HTTP Request Delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	// get the HTML
	NSString *html = [request responseString];
	
	// determine the base URL to use for storage
	NSURL *baseURL = [request originalURL];
	
	//store the retrieved data
	id<ORMMALocalServerDelegate> d = (id<ORMMALocalServerDelegate>)[request.userInfo objectForKey:kORMMALocalServerDelegateKey];
	[self cacheHTML:html
			baseURL:baseURL
	   withDelegate:d];
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
- (NSString *)resourcePathFromBaseURL:(NSURL *)url
{
	// start with the host
	NSMutableString *path = [NSMutableString stringWithCapacity:200];
	[path appendString:[url host]];
	
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


// our cache path will end up being
// ROOT + host + path1 + ... + pathN + resource
- (NSString *)cachePathFromURL:(NSURL *)url
{
	// add the root
	NSString *path = self.cacheRoot;
	
	// add the resource path
	NSString *rp = [self resourcePathFromBaseURL:url];
	
	path = [path stringByAppendingPathComponent:rp];
	
	// done
	return path;
}


@end
