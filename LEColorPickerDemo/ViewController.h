//
//  ViewController.h
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 11-12-12.
//  Copyright (c) 2012 Luis Espinoza. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATPagingView.h"
#import "LEColorPicker.h"

@interface ViewController : UIViewController<ATPagingViewDelegate>
{
    IBOutlet ATPagingView *_pagingView;
    IBOutlet UITextView *_titleTextField;
    IBOutlet UITextView *_bodyTextField;
    IBOutlet UIView *_outputView;
    NSMutableArray *_imagesNamesArray;
}
@end
