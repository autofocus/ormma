//
//  ORMMADataAccessLayer.m
//  ORMMA
//
//  Created by Robert Hedin on 10/15/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMADataAccessLayer.h"



@interface ORMMADataAccessLayer ()


@end




@implementation ORMMADataAccessLayer


#pragma mark -
#pragma mark Constants

NSString * const kORMMALocalServerDatabase = @"ormma.db";



#pragma mark -
#pragma mark Properties



#pragma mark -
#pragma mark Initializers / Memory Management

+ (ORMMADataAccessLayer *)sharedInstance
{
	static ORMMADataAccessLayer *sharedInstance = nil;

    @synchronized( self )
    {
        if ( sharedInstance == nil )
		{
			sharedInstance = [[ORMMADataAccessLayer alloc] init];
			
			// open the database
			[sharedInstance open];
		}
    }
    return sharedInstance;
}


- (ORMMADataAccessLayer *)init
{
	if ( ( self = [super init] ) )
	{
	}
	return self;
}


- (void)dealloc
{
	// shutdown the database
	[self close];
	[super dealloc];
}



#pragma mark -
#pragma mark Database Control

- (BOOL)open
{
	// build path to db
	BOOL opened = NO;
	@synchronized( self )
	{
		if ( m_database == nil )
		{
			NSArray *systemPaths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES ); 
			NSString *basePath = [systemPaths objectAtIndex:0]; 
			NSString *path = [basePath stringByAppendingPathComponent:kORMMALocalServerDatabase];
			
			m_database = [FMDatabase databaseWithPath:path];
			opened = [m_database open];
			if ( !opened )
			{
				// error opening the database, shut it down
				NSLog( @"Could not open the ORMMA database" );
				[m_database release], m_database  = nil;
			}
		}
	}
	return opened;
}


- (void)close
{
	@synchronized( self )
	{
		if ( m_database != nil )
		{
			[m_database close];
			[m_database release], m_database = nil;
		}
	}
}



@end
