//
//  ViewController.m
//  LEColorPickerDemo
//
//  Created by Luis Enrique Espinoza Severino on 11-12-12.
//  Copyright (c) 2012 LuisEspinoza. All rights reserved.
//

#import "ViewController.h"
#import "LEColorPicker.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self populateImagesNamesArray];
    
    [self configurePagingView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)populateImagesNamesArray
{
    NSArray *pngArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"png" inDirectory:@"/."];
    _imagesNamesArray = [[NSMutableArray alloc] init];
    
    for (NSUInteger i=0;i<[pngArray count];i++) {
        NSString *path = [pngArray objectAtIndex:i];
        if ([path rangeOfString:@"Default"].location == NSNotFound) {
            //NSLog(@"string does not contain bla");
            [_imagesNamesArray addObject:path];
        }
    }
}

- (void)configurePagingView
{
    _pagingView.horizontal = YES;
    [_pagingView reloadData];
    
    //Configure the _outputView for the first time.
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:[_imagesNamesArray objectAtIndex:_pagingView.currentPageIndex]];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    
    //This is the magic!
    [self configureOutPutView:image];
}

#pragma mark - ATPagingViewDelegate Methods
- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView
{
    return [_imagesNamesArray count];
}

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index
{
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:[_imagesNamesArray objectAtIndex:index]];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    return imageView;
}

- (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView
{
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:[_imagesNamesArray objectAtIndex:_pagingView.currentPageIndex]];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    
    //This is the magic!
    [self configureOutPutView:image];
}
#pragma mark - LEColorPicker Example Usage
- (void)configureOutPutView:(UIImage*)image
{
    [_activityIndicator startAnimating];
    _activityIndicator.hidden = NO;
    
    [LEColorPicker pickColorFromImage:image onComplete:^(NSDictionary *colorsPickedDictionary) {
        [_activityIndicator stopAnimating];
        _activityIndicator.hidden = YES;
        //HERE THE COLOR CHANGE IS ANIMATED
        [UIView beginAnimations:@"ColorChange" context:nil];
        [UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.5];
        //HERE THE COLOR IS CHANGED
        _outputView.backgroundColor = [colorsPickedDictionary objectForKey:@"BackgroundColor"];
        _titleTextField.textColor = [colorsPickedDictionary objectForKey:@"PrimaryTextColor"];
        _bodyTextField.textColor = [colorsPickedDictionary objectForKey:@"SecondaryTextColor"];
        
        [UIView commitAnimations];
    }];
}
@end

