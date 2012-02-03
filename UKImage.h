//
//  UKImage.h
//  Shirosuke
//
//  Created by CONEJO on 28/05/09.
//  Copyright 2009 La Organización. All rights reserved.
//
#ifndef UKIMAGE_H
#define UKIMAGE_H

#import <UIKit/UIKit.h>

@interface UIImage (UKImage)

-(UIImage*)rotate:(UIImageOrientation)orient;

@end

#endif  // UKIMAGE_H