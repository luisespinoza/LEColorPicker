//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//
//  ATPagingView official version 1.1.
//

#import <Foundation/Foundation.h>

@protocol ATPagingViewDelegate;

// a wrapper around UIScrollView in paging mode, with an API similar to UITableView
@interface ATPagingView : UIView {
    // subviews
    UIScrollView *_scrollView;

    // properties
    id<ATPagingViewDelegate> _delegate;
    CGFloat _gapBetweenPages;
    NSInteger _pagesToPreload;

    // state
    NSInteger _pageCount;
    NSInteger _currentPageIndex;
    NSInteger _firstLoadedPageIndex;
    NSInteger _lastLoadedPageIndex;
    NSMutableSet *_recycledPages;
    NSMutableSet *_visiblePages;

    NSInteger _previousPageIndex;

    BOOL _rotationInProgress;
    BOOL _scrollViewIsMoving;
    BOOL _recyclingEnabled;
    BOOL _horizontal;
}

@property(nonatomic, assign) IBOutlet id<ATPagingViewDelegate> delegate;

@property(nonatomic, assign) CGFloat gapBetweenPages;  // default is 20

@property(nonatomic, assign) NSInteger pagesToPreload;  // number of invisible pages to keep loaded to each side of the visible pages, default is 1

@property(nonatomic, readonly) NSInteger pageCount;

@property(nonatomic, assign) NSInteger currentPageIndex;
@property(nonatomic, assign, readonly) NSInteger previousPageIndex; // only for reading inside currentPageDidChangeInPagingView

@property(nonatomic, assign, readonly) NSInteger firstVisiblePageIndex;
@property(nonatomic, assign, readonly) NSInteger lastVisiblePageIndex;

@property(nonatomic, assign, readonly) NSInteger firstLoadedPageIndex;
@property(nonatomic, assign, readonly) NSInteger lastLoadedPageIndex;

@property(nonatomic, assign, readonly) BOOL moving;
@property(nonatomic, assign) BOOL recyclingEnabled;
@property(nonatomic, assign) BOOL horizontal;   // default YES

- (void)reloadData;  // must be called at least once to display something

- (UIView *)viewForPageAtIndex:(NSUInteger)index;  // nil if not loaded

- (UIView *)dequeueReusablePage;  // nil if none

- (void)willAnimateRotation;  // call this from willAnimateRotationToInterfaceOrientation:duration:

- (void)didRotate;  // call this from didRotateFromInterfaceOrientation:

@end


@protocol ATPagingViewDelegate <NSObject>

@required

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView;

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index;

@optional

- (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView;

- (void)pagesDidChangeInPagingView:(ATPagingView *)pagingView;

// a good place to start and stop background processing
- (void)pagingViewWillBeginMoving:(ATPagingView *)pagingView;
- (void)pagingViewDidEndMoving:(ATPagingView *)pagingView;

@end


@interface ATPagingViewController : UIViewController <ATPagingViewDelegate> {
    ATPagingView *_pagingView;
}

@property(nonatomic, retain) IBOutlet ATPagingView *pagingView;

@end
