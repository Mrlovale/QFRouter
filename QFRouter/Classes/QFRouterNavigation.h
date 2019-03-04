//
//  QFRouterNavigation.h
//  QFRouterDemo
//
//  Created by hlxdev on 2019/2/28.
//  Copyright © 2019 hlxdev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QFRouterNavigation : NSObject

+ (void)autoHidesBottomBarWhenPushed:(BOOL)hide;

+ (UIViewController *)currentViewController;

+ (nullable UINavigationController *)currentNavigationViewController;

+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

+ (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^ __nullable)(void))completion;

+ (void)closeViewControllerAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
