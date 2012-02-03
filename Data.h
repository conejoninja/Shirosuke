//
//  Data.h
//  Shirosuke
//
//  Created by CONEJO on 24/05/09.
//  Copyright 2009 La Organización. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Data : NSObject <NSCoding, NSCopying> {

	NSString *scorelevel;
	
}
@property (nonatomic, retain) NSString *scorelevel;

@end
