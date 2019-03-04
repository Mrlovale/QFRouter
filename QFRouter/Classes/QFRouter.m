//
//  QFRouter.m
//  QFRouterDemo
//
//  Created by hlxdev on 2019/2/27.
//  Copyright © 2019 hlxdev. All rights reserved.
//

#import "QFRouter.h"
#import "QFRouterLogger.h"

static NSString *const QFRouterWildcard = @"*";
static NSString *FFSpecialCharacters = @"/?&.";

static NSString *const QFRouterCoreKey = @"QFRouterCore";
static NSString *const QFRouterCoreBlockKey = @"QFRouterCoreBlock";
static NSString *const QFRouterCoreTypeKey = @"QFRouterCoreType";

NSString *const QFRouterParameterURLKey = @"QFRouterParameterURL";

typedef NS_ENUM(NSInteger,QFRouterType) {
    QFRouterTypeDefault = 0,
    QFRouterTypeObject = 1,
    QFRouterTypeCallback = 2,
};

@interface QFRouter ()

@property (nonatomic, strong) NSMutableDictionary *routers;
@property (nonatomic, strong) QFRouterUnregisterURLHandler routerUnregisterURLHandler;

@end

@implementation QFRouter

+ (instancetype)sharedInstance {
    static QFRouter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - public
+ (void)registerRouterURL:(NSString *)routerURL handler:(QFRouterHandler)handlerBlock {
    QFRouterLog(@"registerRouteURL:%@",routerURL);
    [[self sharedInstance] addRouteURL:routerURL handler:handlerBlock];
}

+ (void)registerObjectRouterURL:(NSString *)routerURL handler:(QFObjectRouterHandler)handlerBlock {
    QFRouterLog(@"registerObjectRouterURL:%@",routerURL);
    [[self sharedInstance] addObjectRouteURL:routerURL handler:handlerBlock];
}

+ (void)registerCallbackRouterURL:(NSString *)routerURL handler:(QFCallbackRouterHandler)handlerBlock {
    QFRouterLog(@"registerCallbackRouterURL:%@",routerURL);
    [[self sharedInstance] addCallbackRouteURL:routerURL handler:handlerBlock];
}

+ (BOOL)canRouterURL:(NSString *)URL {
    return [[self sharedInstance] achieveParametersFromURL:URL] ? YES : NO;
}

+ (void)routerURL:(NSString *)URL {
    [self routerURL:URL withParameters:@{}];
}

+ (void)routerURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters {
    URL = [URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        QFRouterErrorLog(@"Route unregistered URL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return;
    }
    
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    
    if (routerParameters) {
        NSDictionary *coreDic = routerParameters[QFRouterCoreKey];
        QFRouterHandler handler = coreDic[QFRouterCoreBlockKey];
        QFRouterType type = [coreDic[QFRouterCoreTypeKey] integerValue];
        if (type != QFRouterTypeDefault) {
            [self routeTypeCheckLogWithCorrectType:type url:URL];
            return;
        }
        
        if (handler) {
            if (parameters) {
                [routerParameters addEntriesFromDictionary:parameters];
            }
            [routerParameters removeObjectForKey:QFRouterCoreTypeKey];
            handler(routerParameters);
        }
    }
    
}

+ (id)routerObjectURL:(NSString *)URL {
    return [self routerObjectURL:URL withParameters:@{}];
}

+ (id)routerObjectURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters {
    QFRouterErrorLog(@"routerObjectURL:%@",URL);
    URL = [URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        QFRouterErrorLog(@"Route unregistered URL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return nil;
    }
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    
    NSDictionary *coreDic = routerParameters[QFRouterCoreKey];
    QFObjectRouterHandler handler = coreDic[QFRouterCoreBlockKey];
    QFRouterType type = [coreDic[QFRouterCoreTypeKey] integerValue];
    if (type != QFRouterTypeObject) {
        [self routeTypeCheckLogWithCorrectType:type url:URL];
        return nil;
    }
    if (handler) {
        if (parameters.allKeys.count>0) {
            [routerParameters addEntriesFromDictionary:parameters];
        }
        [routerParameters removeObjectForKey:QFRouterCoreKey];
        return handler(routerParameters);
    }
    return nil;
}

+ (void)routerCallbackURL:(NSString *)URL targetCallback:(QFRouterCallback)targetCallback {
    [self routerCallbackURL:URL withParameters:@{} targetCallback:targetCallback];
}

+ (void)routerCallbackURL:(NSString *)URL withParameters:(NSDictionary<NSString *, id> *)parameters targetCallback:(QFRouterCallback)targetCallback {
    QFRouterErrorLog(@"routerCallbackURL:%@",URL);
    URL = [URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSMutableDictionary *routerParameters = [[self sharedInstance] achieveParametersFromURL:URL];
    if(!routerParameters){
        QFRouterErrorLog(@"Route unregistered URL:%@",URL);
        [[self sharedInstance] unregisterURLBeRouterWithURL:URL];
        return;
    }
    
    [routerParameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            routerParameters[key] = [NSString stringWithFormat:@"%@",obj];
        }
    }];
    
    if (routerParameters) {
        NSDictionary *coreDic = routerParameters[QFRouterCoreKey];
        QFCallbackRouterHandler handler = coreDic[QFRouterCoreBlockKey];
        QFRouterType type = [coreDic[QFRouterCoreTypeKey] integerValue];
        if (type != QFRouterTypeCallback) {
            [self routeTypeCheckLogWithCorrectType:type url:URL];
            return;
        }
        if (parameters) {
            [routerParameters addEntriesFromDictionary:parameters];
        }
        
        if (handler) {
            [routerParameters removeObjectForKey:QFRouterCoreKey];
            handler(routerParameters,^(id callbackObjc){
                if (targetCallback) {
                    targetCallback(callbackObjc);
                }
            });
        }
    }
    
}

+ (void)routerUnregisterURLHandler:(QFRouterUnregisterURLHandler)handler {
    [[self sharedInstance] setRouterUnregisterURLHandler:handler];
}

+ (void)unregisterRouterURL:(NSString *)URL {
    [[self sharedInstance] removeRouteURL:URL];
    QFRouterLog(@"unregisterRouterURL:%@\nroutes:%@",URL,[[self sharedInstance] routers]);
}

+ (void)unregisterAllRouters {
    [[self sharedInstance] removeAllRouteURL];
}


+ (void)setLogEnabled:(BOOL)enable {
    [QFRouterLogger enableLog:enable];
}

#pragma mark - privite
- (void)addRouteURL:(NSString *)routeUrl handler:(QFRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routeUrl];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{QFRouterCoreBlockKey:[handlerBlock copy],QFRouterCoreTypeKey:@(QFRouterTypeDefault)};
        subRoutes[QFRouterCoreKey] = coreDic;
    }
}

- (void)addObjectRouteURL:(NSString *)routerURL handler:(QFObjectRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routerURL];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{QFRouterCoreBlockKey:[handlerBlock copy],QFRouterCoreTypeKey:@(QFRouterTypeObject)};
        subRoutes[QFRouterCoreKey] = coreDic;
    }
}

- (void)addCallbackRouteURL:(NSString *)routeURL handler:(QFCallbackRouterHandler)handlerBlock {
    NSMutableDictionary *subRoutes = [self addURLPattern:routeURL];
    if (handlerBlock && subRoutes) {
        NSDictionary *coreDic = @{QFRouterCoreBlockKey:[handlerBlock copy],QFRouterCoreTypeKey:@(QFRouterTypeCallback)};
        subRoutes[QFRouterCoreKey] = coreDic;
    }
}

- (NSMutableDictionary *)achieveParametersFromURL:(NSString *)url {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[QFRouterParameterURLKey] = [url stringByRemovingPercentEncoding];
    
    NSMutableDictionary *subRoutes = self.routers;
    NSArray *pathComponents = [self pathComponentsFromURL:url];
    
    NSInteger pathComponentsSurplus = [pathComponents count];
    BOOL wildcardMatched = NO;
    
    for (NSString *pathComponent in pathComponents) {
        NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch;
        NSArray *subRoutesKeys =[subRoutes.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj2 compare:obj1 options:comparisonOptions];
        }];
        
        for (NSString *key in subRoutesKeys) {
            
            if([pathComponent isEqualToString:key]){
                pathComponentsSurplus --;
                subRoutes = subRoutes[key];
                break;
            }else if([key hasPrefix:@":"] && pathComponentsSurplus == 1){
                subRoutes = subRoutes[key];
                NSString *newKey = [key substringFromIndex:1];
                NSString *newPathComponent = pathComponent;
                
                NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:FFSpecialCharacters];
                NSRange range = [key rangeOfCharacterFromSet:specialCharacterSet];
                
                if (range.location != NSNotFound) {
                    newKey = [newKey substringToIndex:range.location - 1];
                    NSString *suffixToStrip = [key substringFromIndex:range.location];
                    newPathComponent = [newPathComponent stringByReplacingOccurrencesOfString:suffixToStrip withString:@""];
                }
                parameters[newKey] = newPathComponent;
                break;
            }else if([key isEqualToString:QFRouterWildcard] && !wildcardMatched){
                subRoutes = subRoutes[key];
                wildcardMatched = YES;
                break;
            }
        }
    }
    
    if (!subRoutes[QFRouterCoreKey]) {
        return nil;
    }
    
    NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:[[NSURL alloc] initWithString:url] resolvingAgainstBaseURL:false].queryItems;
    
    for (NSURLQueryItem *item in queryItems) {
        parameters[item.name] = item.value;
    }
    
    parameters[QFRouterCoreKey] = [subRoutes[QFRouterCoreKey] copy];
    return parameters;
}

- (NSMutableDictionary *)addURLPattern:(NSString *)URLPattern {
    NSArray *pathComponents = [self pathComponentsFromURL:URLPattern];
    
    NSMutableDictionary *subRoutes = self.routers;
    for (NSString *pathComponent in pathComponents) {
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];
    }
    return subRoutes;
    
}

- (void)unregisterURLBeRouterWithURL:(NSString *)URL {
    if (self.routerUnregisterURLHandler) {
        self.routerUnregisterURLHandler(URL);
    }
}

- (void)removeRouteURL:(NSString *)routeURL {
    if (self.routers.count <= 0) {
        return;
    }
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[self pathComponentsFromURL:routeURL]];
    BOOL firstPoll = YES;
    
    while(pathComponents.count > 0){
        NSString *componentKey = [pathComponents componentsJoinedByString:@"."];
        NSMutableDictionary *route = [self.routers valueForKeyPath:componentKey];
        
        if (route.count > 1 && firstPoll) {
            [route removeObjectForKey:QFRouterCoreKey];
            break;
        }
        if (route.count <= 1 && firstPoll){
            NSString *lastComponent = [pathComponents lastObject];
            [pathComponents removeLastObject];
            NSString *parentComponent = [pathComponents componentsJoinedByString:@"."];
            route = [self.routers valueForKeyPath:parentComponent];
            [route removeObjectForKey:lastComponent];
            firstPoll = NO;
            continue;
        }
        if (route.count > 0 && !firstPoll){
            break;
        }
    }
}

- (void)removeAllRouteURL {
    [self.routers removeAllObjects];
}

- (NSArray*)pathComponentsFromURL:(NSString*)URL {
    
    NSMutableArray *pathComponents = [NSMutableArray array];
    if ([URL rangeOfString:@"://"].location != NSNotFound) {
        NSArray *pathSegments = [URL componentsSeparatedByString:@"://"];
        [pathComponents addObject:pathSegments[0]];
        for (NSInteger idx = 1; idx < pathSegments.count; idx ++) {
            if (idx == 1) {
                URL = [pathSegments objectAtIndex:idx];
            }else{
                URL = [NSString stringWithFormat:@"%@://%@",URL,[pathSegments objectAtIndex:idx]];
            }
        }
    }
    
    if ([URL hasPrefix:@":"]) {
        if ([URL rangeOfString:@"/"].location != NSNotFound) {
            NSArray *pathSegments = [URL componentsSeparatedByString:@"/"];
            [pathComponents addObject:pathSegments[0]];
        }else{
            [pathComponents addObject:URL];
        }
    }else{
        for (NSString *pathComponent in [[NSURL URLWithString:URL] pathComponents]) {
            if ([pathComponent isEqualToString:@"/"]) continue;
            if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
            [pathComponents addObject:pathComponent];
        }
    }
    return [pathComponents copy];
}

+ (void)routeTypeCheckLogWithCorrectType:(QFRouterType)correctType url:(NSString *)URL{
    if (correctType == QFRouterTypeDefault) {
        QFRouterErrorLog(@"You must use [routeURL:] or [routeURL: withParameters:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }else if (correctType == QFRouterTypeObject) {
        QFRouterErrorLog(@"You must use [routeObjectURL:] or [routeObjectURL: withParameters:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }else if (correctType == QFRouterTypeCallback) {
        QFRouterErrorLog(@"You must use [routeCallbackURL: targetCallback:] or [routeCallbackURL: withParameters: targetCallback:] to Route URL:%@",URL);
        NSAssert(NO, @"Method using errors, please see the console log for details.");
    }
}

#pragma mark - getter/setter
- (NSMutableDictionary *)routers {
    if (!_routers) {
        _routers = [NSMutableDictionary dictionary];
    }
    return _routers;
}

@end
