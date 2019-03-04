//
//  QFRouter.h
//  QFRouterDemo
//
//  Created by hlxdev on 2019/2/27.
//  Copyright © 2019 hlxdev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QFRouterNavigation.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const QFRouterParameterURLKey;

typedef void (^QFRouterHandler)(NSDictionary *routerParameters);
typedef id (^QFObjectRouterHandler)(NSDictionary *routerParameters);

typedef void (^QFRouterCallback)(id callbackObjc);
typedef void (^QFCallbackRouterHandler)(NSDictionary *routerParameters,QFRouterCallback targetCallback);

typedef void (^QFRouterUnregisterURLHandler)(NSString *routerURL);

@interface QFRouter : NSObject


/**
 注册URL，与routerURL跟routerURL:withParameters:配合使用

 @param routerURL 要注册的URL
 @param handlerBlock 注册之后被调用的回调
 */
+ (void)registerRouterURL:(NSString *)routerURL handler:(QFRouterHandler)handlerBlock;


/**
 注册URL，与routeObjectURL跟routerObjectURL:withParameters:配合使用

 @param routerURL 要注册的URL
 @param handlerBlock 注册之后被调用的回调,可在回调中返回一个Object
 */
+ (void)registerObjectRouterURL:(NSString *)routerURL handler:(QFObjectRouterHandler)handlerBlock;


/**
 注册URL，与routerCallbackURL:targetCallback:跟routerCallbackURL:withParameters:targetCallback配合使用

 @param routerURL 要注册的URL
 @param handlerBlock URL被调用后的回调,handlerBlock中有一个targetCallBack,对应 routeCallbackURL:targetCallBack:和routeCallbackURL:withParameters:targetCallBack:中的 targetCallBack，可用于异步回调返回一个Object
 */
+ (void)registerCallbackRouterURL:(NSString *)routerURL handler:(QFCallbackRouterHandler)handlerBlock;


/**
 判断URL是否可被Route（是否已经注册）

 @param URL 要判断的URL
 @return 是否可被Route
 */
+ (BOOL)canRouterURL:(NSString *)URL;


/**
 Route一个URL

 @param URL 要route的URL
 */
+ (void)routerURL:(NSString *)URL;


/**
 Route一个URL，并带上额外参数

 @param URL 要route的URL
 @param parameters 额外参数
 */
+ (void)routerURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters;


/**
 Route一个URL，可获得返回的Object

 @param URL 要route的URL
 @return 返回的Object
 */
+ (id)routerObjectURL:(NSString *)URL;


/**
 Route一个URL，并带上额外参数，可获得返回的Object

 @param URL 要route的URL
 @param parameters 额外参数
 @return 返回的Object
 */
+ (id)routerObjectURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters;


/**
 Route一个URL,targetCallBack可异步回调以返回一个Object

 @param URL 要route的URL
 @param targetCallback 异步回调
 */
+ (void)routerCallbackURL:(NSString *)URL targetCallback:(QFRouterCallback)targetCallback;


/**
 Route一个URL,并带上额外参数,targetCallBack可异步回调以返回一个Object

 @param URL 要route的URL
 @param parameters 额外参数
 @param targetCallback 异步回调
 */
+ (void)routerCallbackURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters targetCallback:(QFRouterCallback)targetCallback;


/**
 Route一个未注册URL时回调

 @param handler 回调
 */
+ (void)routerUnregisterURLHandler:(QFRouterUnregisterURLHandler)handler;


/**
 取消注册某个URL

 @param URL 要被取消注册的URL
 */
+ (void)unregisterRouterURL:(NSString *)URL;


/**
 取消注册所有URL
 */
+ (void)unregisterAllRouters;


/**
 是否显示Log，用于调试

 @param enable YES or NO，默认为NO
 */
+ (void)setLogEnabled:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
