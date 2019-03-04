//
//  QFRouterNavigation.m
//  QFRouterDemo
//
//  Created by hlxdev on 2019/2/28.
//  Copyright © 2019 hlxdev. All rights reserved.
//

#import "QFRouterNavigation.h"

@interface QFRouterNavigation()

@property (nonatomic,assign) BOOL autoHidesBottomBar;
@property (nonatomic,assign) BOOL autoHidesBottomBarConfigured;

@end

@implementation QFRouterNavigation

+ (instancetype)sharedInstance {
    static QFRouterNavigation *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (void)autoHidesBottomBarWhenPushed:(BOOL)hide {
    [[self sharedInstance] setAutoHidesBottomBarConfigured:hide];
    [[self sharedInstance] setAutoHidesBottomBar:hide];
}

+ (id<UIApplicationDelegate>)applicationDelegate {
    return [UIApplication sharedApplication].delegate;
}

+ (UIViewController *)currentViewController {
    UIViewController *rootViewController = self.applicationDelegate.window.rootViewController;
    return [self currentViewControllerFrom:rootViewController];
}

+ (UIViewController *)currentViewControllerFrom:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        return [self currentViewControllerFrom:navigationController.viewControllers.lastObject];
    } else if([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)viewController;
        return [self currentViewControllerFrom:tabBarController.selectedViewController];
    } else if(viewController.presentedViewController != nil) {
        return [self currentViewControllerFrom:viewController.presentedViewController];
    } else {
        return viewController;
    }
}

+ (nullable UINavigationController *)currentNavigationViewController {
    UIViewController *currentViewController = [self currentViewController];
    return currentViewController.navigationController;
}

+ (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!viewController) return;
    
    UINavigationController *currentNav = [self currentNavigationViewController];
    [currentNav pushViewController:viewController animated:animated];
}

+ (void)presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^ __nullable)(void))completion {
    if (!viewController) return;
    
    UIViewController *currentCtrl = [self currentViewController];
    if (!currentCtrl) return;
    
    [currentCtrl presentViewController:viewController animated:animated completion:completion];
}

+ (void)closeViewControllerAnimated:(BOOL)animated {
    UIViewController *currentViewController = [self currentViewController];
    if(!currentViewController) return;
    
    if(currentViewController.navigationController) {
        if(currentViewController.navigationController.viewControllers.count == 1) {
            if(currentViewController.presentingViewController) {
                [currentViewController dismissViewControllerAnimated:animated completion:nil];
            }
        } else {
            [currentViewController.navigationController popViewControllerAnimated:animated];
        }
    } else if(currentViewController.presentingViewController) {
        [currentViewController dismissViewControllerAnimated:animated completion:nil];
    }
}

@end
