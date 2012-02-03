//
//  Data.m
//  Shirosuke
//
//  Created by CONEJO on 24/05/09.
//  Copyright 2009 La Organización. All rights reserved.
//

#import "Data.h"


@implementation Data
@synthesize scorelevel;


#pragma mark NSCoding
- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:scorelevel forKey:@"score"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	if(self=[super init]){
		self.scorelevel = [decoder decodeObjectForKey:@"score"];
	}
	return self;
}

#pragma mark -


#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
	Data *copy = [[[self class] allocWithZone:zone] init];
	scorelevel = [self.scorelevel copy];
	return copy;
}




@end
