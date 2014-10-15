//
//  SPLogger.m
//  SponsoPay iOS SDK
//
//  Created by David Davila on 8/21/12.
//  Copyright (c) 2012 SponsorPay. All rights reserved.
//

#import "SPLogger.h"
#import "SPLogAppender.h"

//setting the verbosity to Info by default
static SPLogLevel SPCurrentLogLevel = SPLogLevelInfo;

void SPLogSetLevel(SPLogLevel level)
{
    SPCurrentLogLevel = level;
}

void _SPLogDebug(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelDebug) {
        format = [NSString stringWithFormat:@"[SP Debug]: %@", format];

        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

void _SPLogWarn(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelWarn) {
        format = [NSString stringWithFormat:@"[SP Warn]: %@", format];
        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

void _SPLogInfo(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelInfo) {
        format = [NSString stringWithFormat:@"[SP Info]: %@", format];
        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

void _SPLogError(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelError) {
        format = [NSString stringWithFormat:@"[SP Error]: %@", format];
        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

void _SPLogFatal(NSString *format, ...)
{
    if (SPCurrentLogLevel <= SPLogLevelFatal) {
        format = [NSString stringWithFormat:@"[SP Fatal]: %@", format];
        va_list args;
        va_start(args, format);
        [[SPLogger sharedInstance] logFormat:format arguments:args];
        va_end(args);
    }
}

@interface SPLogger ()

@property (nonatomic, strong) NSMutableSet *loggers;

@end

@implementation SPLogger

+ (void)addLogger:(id<SPLogAppender>)logger
{
    if ([logger conformsToProtocol:@protocol(SPLogAppender)]) {
        [[SPLogger sharedInstance] addLogger:logger];
    } else {
        SPLogError(@"Logger %@ does not conform to protocol SPLogAppender", NSStringFromClass([logger class]));
    }
}

+ (void)removeLogger:(id<SPLogAppender>)logger
{
    if ([[[SPLogger sharedInstance] loggers] containsObject:logger]) {
        [[[SPLogger sharedInstance] loggers] removeObject:logger];
    } else {
        SPLogError(@"Ther is no Logger %@ in the collection", NSStringFromClass([logger class]));
    }
}

+ (void)removeAllLoggers
{
    [[[SPLogger sharedInstance] loggers] removeAllObjects];
}


- (id)init
{
    self = [super init];

    if (self) {
        _loggers = [NSMutableSet set];
    }

    return self;
}

- (void)logFormat:(NSString *)format arguments:(va_list)arguments
{
    for (id<SPLogAppender> logger in self.loggers) {
        va_list args_copy;
        va_copy(args_copy, arguments);

        [logger logFormat:format arguments:args_copy];
        va_end(args_copy);
    };
}

- (void)addLogger:(id<SPLogAppender>)logger
{
    [self.loggers addObject:logger];
}

+ (SPLogger *)sharedInstance
{
    static SPLogger *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SPLogger alloc] init];
    });

    return sharedInstance;
}

@end
