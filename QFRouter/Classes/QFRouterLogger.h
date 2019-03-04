//
//  QFRouterLogger.h
//  QFRouterDemo
//
//  Created by hlxdev on 2019/2/27.
//  Copyright © 2019 hlxdev. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define QFRouterLogLevel(lvl,fmt,...)\
[QFRouterLogger log : YES                                      \
level : lvl                                                  \
format : (fmt), ## __VA_ARGS__]

#define QFRouterLog(fmt,...)\
QFRouterLogLevel(QFRouterLoggerLevelInfo,(fmt), ## __VA_ARGS__)

#define QFRouterWarningLog(fmt,...)\
QFRouterLogLevel(QFRouterLoggerLevelWarning,(fmt), ## __VA_ARGS__)

#define QFRouterErrorLog(fmt,...)\
QFRouterLogLevel(QFRouterLoggerLevelError,(fmt), ## __VA_ARGS__)


typedef NS_ENUM(NSUInteger,QFRouterLoggerLevel){
    QFRouterLoggerLevelInfo = 1,
    QFRouterLoggerLevelWarning ,
    QFRouterLoggerLevelError ,
};

@interface QFRouterLogger : NSObject

@property(class , readonly, strong) QFRouterLogger *sharedInstance;

+ (BOOL)isLoggerEnabled;

+ (void)enableLog:(BOOL)enableLog;

+ (void)log:(BOOL)asynchronous
      level:(NSInteger)level
     format:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
