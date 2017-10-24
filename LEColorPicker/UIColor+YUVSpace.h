//
//  UIColor+LEColorPicker.h
//  LEColorPicker
//
//  Created by Luis Enrique Espinoza Severino on 03-12-12.
//  Copyright (c) 2012 Luis Espinoza. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (YUVSpace)

+ (float) yComponentFromColor:(nullable UIColor*)color;
+ (float) uComponentFromColor:(nullable UIColor*)color;
+ (float) vComponentFromColor:(nullable UIColor*)color;
+ (float) YUVSpaceDistanceToColor:(nullable UIColor*)toColor fromColor:(nullable UIColor*)fromColor;
+ (float) YUVSpaceSquareDistanceToColor:(nullable UIColor *)toColor fromColor:(nullable UIColor *)fromColor;

@end

NS_ASSUME_NONNULL_END
