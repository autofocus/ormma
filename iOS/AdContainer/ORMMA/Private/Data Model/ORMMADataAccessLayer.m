//
//  ORMMADataAccessLayer.m
//  ORMMA
//
//  Created by Robert Hedin on 10/15/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import "ORMMADataAccessLayer.h"
#import "ORMMALocalServer.h"



@interface ORMMADataAccessLayer ()

@property( nonatomic, copy ) NSString *databasePath;

- (void)updateDatabaseSchemaForRecovery:(BOOL)recovery;
- (BOOL)processSchemaFile:(NSString *)path;

@end




@implementation ORMMADataAccessLayer


#pragma mark -
#pragma mark Constants




#pragma mark -
#pragma mark Properties

@dynamic databasePath;



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
			
			abort();
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
#pragma mark Dynamic Properties

- (NSString *)databasePath
{
	NSArray *systemPaths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES ); 
	NSString *basePath = [systemPaths objectAtIndex:0]; 
	NSString *path = [basePath stringByAppendingPathComponent:@"ormma.db"];
	return path;
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
			m_database = [FMDatabase databaseWithPath:self.databasePath];
			opened = [m_database open];
			if ( !opened )
			{
				// error opening the database, shut it down
				NSLog( @"Could not open the ORMMA database" );
				[m_database release], m_database  = nil;
			}
			
			// the database is opened, update the schema if necessary
			[self updateDatabaseSchemaForRecovery:NO];
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



#pragma mark -
#pragma mark Schema Management

- (void)updateDatabaseSchemaForRecovery:(BOOL)recovery
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"ORMMA"
													 ofType:@"bundle"];
	if ( bundlePath == nil )
	{
		[NSException raise:@"Invalid Build Detected"
					format:@"Unable to find ORMMA.bundle. Make sure it is added to your resources!"];
	}
	m_ormmaBundle = [NSBundle bundleWithPath:bundlePath];
	NSString *sqlPath;
	
	// this is only called on database open.
	// the database object is already locked, nothing else can happen until 
	// we're finished, no need for more locks.
	
	// determine the current database version
	NSInteger version = 0;
	FMResultSet *rs = [m_database executeQuery:@"SELECT version FROM schema_version"];
	if ( [rs next] )
	{
		version = [rs intForColumn:@"version"];
	}
	
	NSLog( @"Current ORMMA Database Version is: %i", version );
	
	// now see if there are any new schema files we need to apply
	for ( version++; /* no condition */ ; version++ )
	{
		sqlPath = [m_ormmaBundle pathForResource:[NSString stringWithFormat:@"%i", version]
										  ofType:@"sql"];
		if ( sqlPath == nil )
		{
			// no more files to process
			break;
		}
		NSLog( @"Looking for ORMMA Schema File: %@", sqlPath );
		
		// we have a schema file, process it
		if ( ![self processSchemaFile:sqlPath] )
		{
			// unable to upgrade the schema, we need to try to recover, so
			// let's trash the cache completely (since we will lose our cache
			// management data anyway)
			[ORMMALocalServer removeAllCachedResources];
			
			// Now, let's trash the entire database
			[self close];
			[fm removeItemAtPath:self.databasePath 
						   error:NULL];
			[self open];
			
			if ( recovery )
			{
				// we're already trying to recover, something is woefully wrong
				// let's just crash the app and hope things pick up correctly
				// on a restart
				[NSException raise:@"Database Recovery Failure"
							format:@"The initial database recovery failed; attempting to correct on restart"];
				return;
			}
			
			// this is the first time we've tried this, so let's just restart
			// the schema update process
			[self updateDatabaseSchemaForRecovery:YES];
			return;
		}

		// now update the schema version
		[m_database beginTransaction];
		[m_database executeUpdate:@"UPDATE schema_version SET version = ?", [NSNumber numberWithInt:version]];
		[m_database commit];
	}
}



- (BOOL)processSchemaFile:(NSString *)path
{
	// assume data is in UTF8
	NSLog( @"Processing ORMMA Schema File: %@", path );
	NSString *string = [NSString stringWithContentsOfFile:path
												 encoding:NSUTF8StringEncoding
													error:NULL];
	
	// first, let's remove '/*' + '*/' comments
	NSRange commentStart;
	NSRange commentEnd;
	for ( commentStart = [string rangeOfString:@"/*"]; commentStart.location != NSNotFound; commentStart = [string rangeOfString:@"/*"] )
	{
		// we've found the start of a comment, now find the end
		commentEnd = [string rangeOfString:@"*/"];
		if ( commentEnd.location == NSNotFound)
		{
			// no end of comment, bail
			[NSException raise:@"Syntax Error"
						format:@"Error in SQL file: no end of comment."];
		}
		if ( commentEnd.location < commentStart.location )
		{
			// end of comment before start of comment, bail
			[NSException raise:@"Syntax Error"
						format:@"Error in SQL file: end of comment before start."];
		}
		
		// ok we've got the bounds of the comment
		NSRange comment;
		comment.location = commentStart.location;
		comment.length = ( 2 + ( commentEnd.location - commentStart.location ) );
		string = [string stringByReplacingCharactersInRange:comment
												 withString:@""];
	}	
	
	// now let's process the file, line by line
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	NSMutableString *sql = [NSMutableString stringWithCapacity:1000];
	for ( NSString *line in lines )
	{
		// remove comment to end of line
		NSArray *text = [line componentsSeparatedByString:@"--"];
		if ( text.count == 0 )
		{
			// nothing to do
			continue;
		} 
		NSString *workingLine = [[text objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ( workingLine.length > 0 )
		{
			
			[sql appendString:@" "];
			[sql appendString:workingLine];
			if ( [workingLine hasSuffix:@";"] )
			{
				// execute SQL command
				[m_database beginTransaction];
				NSLog( @"Executing SQL: %@", sql );
				[m_database executeUpdate:sql];
//				if ( ![m_database executeUpdate:sql] )
//				{
//					[m_database rollback];
//					NSLog( @"ORMMA Database Error: %d: %@", [m_database lastErrorCode], [m_database lastErrorMessage] );
//					return NO;
//				}
				[m_database commit];
				
				// now clear the SQL for the next loop
				NSRange deleteRange = { 0, sql.length };
				[sql deleteCharactersInRange:deleteRange];
			}
		}
	}
	
	return YES;
}



@end
