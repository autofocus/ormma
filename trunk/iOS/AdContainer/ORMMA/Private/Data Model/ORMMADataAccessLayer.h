//
//  ORMMADataAccessLayer.h
//  ORMMA
//
//  Created by Robert Hedin on 10/15/10.
//  Copyright 2010 The Weather Channel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"


@interface ORMMADataAccessLayer : NSObject 
{
@private
	FMDatabase *m_database;
	NSBundle *m_ormmaBundle;
}

// designated accessor for the singleton instance
+ (ORMMADataAccessLayer *)sharedInstance;


- (BOOL)open;
- (void)close;

@end
