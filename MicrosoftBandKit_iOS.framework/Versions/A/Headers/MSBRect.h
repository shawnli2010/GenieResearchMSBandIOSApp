//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface MSBRect : NSObject

@property(nonatomic, assign)    UInt16      x;
@property(nonatomic, assign)    UInt16      y;
@property(nonatomic, assign)    UInt16      width;
@property(nonatomic, assign)    UInt16      height;

+(MSBRect *)rectwithX:(UInt16)x y:(UInt16)y width:(UInt16)width height:(UInt16)height;

@end
