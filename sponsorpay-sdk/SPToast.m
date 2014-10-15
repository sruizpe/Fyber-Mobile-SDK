//
//  SPToast.m
//  SPToast (iToast)
//
//  Created by Diallo Mamadou Bobo on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SPToast.h"
#import "SPLogger.h"


NSTimeInterval const SPToastDurationLong = 10.;
NSTimeInterval const SPToastDurationShort = 1.;
NSTimeInterval const SPToastDurationNormal = 3.;

static SPToast *SPToastDequeuedToast = nil;


@interface SPToast ()

@property (nonatomic, copy, readwrite) NSString *text;

@property (nonatomic, copy) SPToastSettings *settings;
@property (nonatomic, assign) SPToastType type;

@property (nonatomic, strong) UIView *toastView;

@end


@implementation SPToast {
    @private
    SPToastSettings *settings;
    NSString *text;
    SPToastType type;

    UIView *toastView;

    BOOL isObservingDidBecomeActiveNotification;
}

@synthesize type;

#pragma mark Custom Accessors

- (void)setText:(NSString *)newText
{
    //
    // Check parameter.
    //

    // TODO: Use stringification macros once merged with branch containing these.

    NSAssert(
    !newText || [newText isKindOfClass:[NSString class]],
    @"Expecting newText parameter to be kind of class NSString.");

    //
    // Set new text.
    //

    self->text = [newText copy];
}


- (NSString *)text
{
    return self->text;
}


- (void)setSettings:(SPToastSettings *)newSettings
{
    //
    // Check parameter.
    //

    NSAssert(
    !newSettings || [newSettings isKindOfClass:[SPToastSettings class]],
    @"Expecting newSettings parameter to be kind of class %@.",
    NSStringFromClass([SPToastSettings class]));

    //
    // Set new settings.
    //

    self->settings = [newSettings copy];
}

- (SPToastSettings *)settings
{
    return self->settings ? self->settings : [SPToastSettings sharedSettings];
}

- (void)setType:(SPToastType)newType
{
    //
    // Check parameter.
    //

    // TODO: Use stringification macros once merged with branch containing these.

    NSAssert(
    SPToastTypeMin <= newType && SPToastTypeMax >= newType,
    @"newType parameter contains an invalid SPToastType value.");

    //
    // Check state.
    //

    NSAssert(!self->toastView, @"Cannot change type once toast is shown.");

    //
    // Set new type.
    //

    self->type = newType;
}

#pragma mark  
#pragma mark User Interface

- (UIView *)toastView
{
    return self->toastView;
}

- (void)setToastView:(UIView *)newToastView
{
    //
    // Check parameter.
    //

    NSAssert(
    !newToastView || [newToastView isKindOfClass:[UIView class]],
    @"Expecting newToastView to be kind of class UIView.");

    //
    // Check state.
    //

    if (newToastView == self->toastView) {
        return;
    }

    //
    // Set new toast view.
    //

    [self->toastView removeFromSuperview];

    self->toastView = newToastView;
}


#pragma mark  
#pragma mark Public Methods -

#pragma mark  
#pragma mark Enqueuing Toasts

+ (SPToast *)dequeuedToast
{
    return SPToastDequeuedToast;
}

+ (SPToast *)enqueueToastOfType:(SPToastType)aType
                       withText:(NSString *)aText
                       settings:(SPToastSettings *)optionalSettings
{
    SPToast *const result = [[self alloc]
    initWithType:aType
            text:aText];

    if (optionalSettings) {
        result.settings = optionalSettings;
    }

    SPLogDebug(@"### Enqueuing toast with text: %@", aText);

    [self addToastToQueue:result];

    return result;
}

+ (SPToast *)enqueueToastWithText:(NSString *)aText
{
    return [self
    enqueueToastOfType:SPToastTypeNone
              withText:aText
              settings:nil];
}

#pragma mark  
#pragma mark Showing Toasts

+ (SPToast *)showToastOfType:(SPToastType)aType
                    withText:(NSString *)aText
                    settings:(SPToastSettings *)optionalSettings
{
    SPToast *const result = [[self alloc]
    initWithType:aType
            text:aText];

    if (optionalSettings) {
        result.settings = optionalSettings;
    }

    SPLogDebug(@"### Showing toast with text: %@", aText);

    // TODO: Enqueue toast if a toast is currently being shown.

    [result addToastViewToWindow];

    return result;
}

+ (SPToast *)showToastWithText:(NSString *)aText
{
    return [self
    showToastOfType:SPToastTypeDefault
           withText:aText
           settings:nil];
}

#pragma mark  
#pragma mark Hiding Toasts

- (void)hide
{
    [self removeToastView];
}

#pragma mark  
#pragma mark  
#pragma mark Private Methods -

#pragma mark  
#pragma mark Initialising

- (instancetype)initWithType:(SPToastType)aType text:(NSString *)someText
{
    self = [super init];

    if (self) {
        self.text = someText;
        self.type = aType;
    }

    return self;
}

#pragma mark  
#pragma mark Managing the Toast View

- (void)addToastViewToWindow
{
    //
    // Check state.
    //

    if (self->toastView) {
        // This toast is currently being shown.
        return;
    }

    //
    // Create toast view.
    //

    SPToastSettings *const settingsOfSelf = self.settings;

    UIImage *const image = [settingsOfSelf imageForType:self.type];
    UIFont *const font = [UIFont systemFontOfSize:16];

    // Set correct orientation/location regarding device orientation
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[[UIApplication sharedApplication] statusBarOrientation];

    NSInteger widthConstraint = UIInterfaceOrientationIsPortrait(orientation) ? 280 : 460;
    CGSize toastConstraint = CGSizeMake(widthConstraint, 60);
    CGSize textSize = [text sizeWithFont:font constrainedToSize:toastConstraint];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, textSize.width + 5, textSize.height + 5)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = font;
    label.text = text;
    label.numberOfLines = 0;
    label.shadowColor = [UIColor darkGrayColor];
    label.shadowOffset = CGSizeMake(1, 1);

    UIButton *const newToastView = [UIButton buttonWithType:UIButtonTypeCustom];

    if (image) {
        newToastView.frame = CGRectMake(0, 0, image.size.width + textSize.width + 15, MAX(textSize.height, image.size.height) + 10);
        label.center = CGPointMake(image.size.width + 10 + (newToastView.frame.size.width - image.size.width - 10) / 2, newToastView.frame.size.height / 2);
    } else {
        newToastView.frame = CGRectMake(0, 0, textSize.width + 10, textSize.height + 10);
        label.center = CGPointMake(newToastView.frame.size.width / 2, newToastView.frame.size.height / 2);
    }
    CGRect lbfrm = label.frame;
    lbfrm.origin.x = ceil(lbfrm.origin.x);
    lbfrm.origin.y = ceil(lbfrm.origin.y);
    label.frame = lbfrm;
    [newToastView addSubview:label];

    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.frame = CGRectMake(5, (newToastView.frame.size.height - image.size.height) / 2, image.size.width, image.size.height);
        [newToastView addSubview:imageView];
    }

    newToastView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    newToastView.layer.cornerRadius = 5;


    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIViewController *rootViewController = keyWindow.rootViewController;
    CGRect boundsOfParent = rootViewController.view.bounds;
    CGPoint pointOfToastInParent;


    if (settingsOfSelf.gravity == SPToastGravityTop) {
        pointOfToastInParent = CGPointMake(boundsOfParent.size.width / 2, 45);
    } else if (settingsOfSelf.gravity == SPToastGravityBottom) {
        pointOfToastInParent = CGPointMake(boundsOfParent.size.width / 2, boundsOfParent.size.height - 45);
    } else if (settingsOfSelf.gravity == SPToastGravityCenter) {
        pointOfToastInParent = CGPointMake(boundsOfParent.size.width / 2, boundsOfParent.size.height / 2);
    } else {
        pointOfToastInParent = settingsOfSelf.position;
    }

    pointOfToastInParent = CGPointMake(
    pointOfToastInParent.x + settingsOfSelf.offsetLeft,
    pointOfToastInParent.y + settingsOfSelf.offsetTop);


    newToastView.center = pointOfToastInParent;

    if ([newToastView respondsToSelector:@selector(setAccessibilityIdentifier:)]) {
        [newToastView setAccessibilityIdentifier:@"ToastView"];
    }

    [rootViewController.view addSubview:newToastView];

    self->toastView = newToastView;

    [newToastView addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchDown];

    [self setUpHideTimer];
    [[self class] addActiveToast:self];
}

- (void)removeToastView
{
    if (!self->toastView) {
        return;
    }

    [self stopObservingDidBecomeActiveNotification];

    [UIView animateWithDuration:0.2 animations:^(void) {
        self.toastView.alpha = 0.;
    }
    completion:^(BOOL finished) {
        self.toastView = nil;

        [[self class] removeActiveToast:self];
            
        if ([[self class] dequeuedToast] == self) {
            [[self class] setDequeuedToast:nil];
            [[self class] scheduleDequeuingOfNextToast];
        }
    }];
}

#pragma mark  
#pragma mark Managing the Hide Timer

- (void)handleHideToastTimer:(NSTimer *)theTimer
{
    [self removeToastView];
}

- (void)scheduleHideTimer
{
    NSTimer *const hideTimer = [NSTimer
    timerWithTimeInterval:self.settings.duration
                   target:self
                 selector:@selector(handleHideToastTimer:)
                 userInfo:nil
                  repeats:NO];

    [[NSRunLoop mainRunLoop] addTimer:hideTimer forMode:NSDefaultRunLoopMode];
}

- (void)setUpHideTimer
{
    //
    // Check state.
    //

    if (UIApplicationStateBackground == [[UIApplication sharedApplication] applicationState]) {
        // Postpone the scheduling the hide timer -- it would fire most probably
        // immediately after the app has become active again.
        [self startObservingDidBecomeActiveNotification];
        return;
    }

    //
    // Set up hide timer.
    //

    [self scheduleHideTimer];
}

#pragma mark  
#pragma mark Observing Application Notifications

- (void)handleApplicationDidBecomeActiveNotification:(NSNotification *)
        notification
{
    [self scheduleHideTimer];
    [self stopObservingDidBecomeActiveNotification];
}

- (void)startObservingDidBecomeActiveNotification
{
    //
    // Check state.
    //

    if (self->isObservingDidBecomeActiveNotification) {
        return;
    }

    //
    // Start observing.
    //

    [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(handleApplicationDidBecomeActiveNotification:)
           name:UIApplicationDidBecomeActiveNotification
         object:nil];

    self->isObservingDidBecomeActiveNotification = YES;
}

- (void)stopObservingDidBecomeActiveNotification
{
    //
    // Check state.
    //

    if (!self->isObservingDidBecomeActiveNotification) {
        return;
    }

    //
    // Stop observing.
    //

    [[NSNotificationCenter defaultCenter]
    removeObserver:self
              name:UIApplicationDidBecomeActiveNotification
            object:nil];

    self->isObservingDidBecomeActiveNotification = NO;
}

#pragma mark  
#pragma mark Managing the Toast Queue

+ (void)addToastToQueue:(SPToast *)aToast
{
    //
    // Check parameter.
    //

    // TODO: Use stringification macros once merged with branch containing these.

    NSAssert(
    [aToast isKindOfClass:[SPToast class]],
    @"Expecting aToast parameter to be kind of class %@.",
    NSStringFromClass([SPToast class]));

    //
    // Check state.
    //

    NSMutableArray *const toastQueue = [self toastQueue];

    NSAssert(
    NSNotFound == [toastQueue indexOfObjectIdenticalTo:aToast],
    @"The toast %@ is already part of the toast queue.",
    aToast);

    //
    // Add toast queue.
    //

    [toastQueue addObject:aToast];
    [self scheduleDequeuingOfNextToast];
}

+ (void)dequeueNextToast
{
    NSMutableArray *const toastQueue = [self toastQueue];
    SPToast *const newDequeuedToast = [toastQueue lastObject];

    [toastQueue removeLastObject];

    [self setDequeuedToast:newDequeuedToast];

    [newDequeuedToast addToastViewToWindow];
}

+ (void)scheduleDequeuingOfNextToast
{
    //
    // Schedule dequeueing of next toast.
    //

    dispatch_async(dispatch_get_main_queue(), ^(void) {
    
        if ( [self dequeuedToast] )
        {
            // There is currently a dequeued toast. Leave.
            return;
        }
        
        [self dequeueNextToast];
    });
}

+ (void)setDequeuedToast:(SPToast *)newDequeuedToast
{
    //
    // Check parameter.
    //

    NSAssert(
    !newDequeuedToast || [newDequeuedToast isKindOfClass:[SPToast class]],
    @"Expecting newDequeuedToast parameter to be kind of class %@.",
    NSStringFromClass([SPToast class]));

    //
    // Set new dequeued toast.
    //

    SPToastDequeuedToast = newDequeuedToast;
}

+ (NSMutableArray *)toastQueue
{
    static NSMutableArray *toastQueue = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^(void) {
        toastQueue = [NSMutableArray new];
    });

    return toastQueue;
}

#pragma mark  
#pragma mark Managing Active Toasts

/*!
    \brief Private array holding all toast instances that are scheduled to show 
        or are showing their toast view.
    \note Since the hide timer is now scheduled only if the app is active (in
        order to guarantee that the toast is not hidden too early) there is no
        other object retaining those toasts.
*/
+ (NSMutableArray *)activeToasts
{
    static NSMutableArray *activeToasts = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^(void) {
        activeToasts = [NSMutableArray new];
    });

    return activeToasts;
}

+ (void)addActiveToast:(SPToast *)toast
{
    //
    // Check parameter.
    //

    NSAssert(
    [toast isKindOfClass:[SPToast class]],
    @"Expecting toast to be kind of class %@.",
    NSStringFromClass([SPToast class]));

    //
    // Add toast.
    //

    if (NSNotFound == [[self activeToasts] indexOfObjectIdenticalTo:toast]) {
        [[self activeToasts] addObject:toast];
    }
}

+ (void)removeActiveToast:(SPToast *)toast
{
    //
    // Check parameter.
    //

    NSAssert(
    [toast isKindOfClass:[SPToast class]],
    @"Expecting toast to be kind of class %@.",
    NSStringFromClass([SPToast class]));

    //
    // Remove toast.
    //

    NSUInteger const indexOfToast = [[self activeToasts]
    indexOfObjectIdenticalTo:toast];

    if (NSNotFound != indexOfToast) {
        [[self activeToasts] removeObjectAtIndex:indexOfToast];
    }
}

#pragma mark  
#pragma mark NSObject: Creating, Copying, and Deallocating Objects

- (void)dealloc
{
    SPLogDebug(@"### Deallocating SPToast<%p>", self);

    self.toastView = nil;

    [self stopObservingDidBecomeActiveNotification];
}

@end


#pragma mark  
#pragma mark  
#pragma mark  

@interface SPToastSettings ()

#pragma mark  
#pragma mark Property Declaration Overrides -

@property (nonatomic, assign, readwrite) BOOL positionIsSet;

#pragma mark  
#pragma mark Private Properties

@property (nonatomic, copy) NSMutableDictionary *imagesMutable;
@property (nonatomic, copy, readonly) NSMutableDictionary *imagesMutableLazy;

@end


#pragma mark  
#pragma mark  
#pragma mark  

@implementation SPToastSettings {
    @private

    NSTimeInterval duration;
    SPToastGravity gravity;
    NSMutableDictionary *imagesMutable;
    CGFloat offsetLeft;
    CGFloat offsetTop;
    CGPoint position;
    BOOL positionIsSet;
}

#pragma mark  
#pragma mark Public Properties -
#pragma mark  

@synthesize duration = duration;
@synthesize gravity = gravity;
@synthesize offsetLeft = offsetLeft;
@synthesize offsetTop = offsetTop;
@synthesize position = position;

#pragma mark  

- (BOOL)positionIsSet
{
    return self->positionIsSet ? YES : NO;
}

- (void)setGravity:(SPToastGravity)newGravity
{
    //
    // Check parameter.
    //

    // TODO: Use stringification macros once merged with branch containing these.

    NSAssert(
    SPToastGravityMin <= newGravity && SPToastGravityMax >= newGravity,
    @"newGravity parameter contains invalid SPToastGravity value.");

    //
    // Set new gravity.
    //

    self->gravity = newGravity;
}

- (void)setPosition:(CGPoint)newPosition
{
    self->position = newPosition;
    self.positionIsSet = YES;
}

- (void)setPositionIsSet:(BOOL)newPositionIsSet
{
    self->positionIsSet = newPositionIsSet ? YES : NO;
}

#pragma mark  
#pragma mark Private Properties -
#pragma mark  

@synthesize imagesMutable;

- (NSMutableDictionary *)imagesMutableLazy
{
    NSMutableDictionary *result = self.imagesMutable;

    if (!result) {
        result = [NSMutableDictionary new];
        self.imagesMutable = result;
    }

    return result;
}

#pragma mark  
#pragma mark Public Methods -

#pragma mark  
#pragma mark Initialising

- (instancetype)init
{
    self = [super init];

    if (self) {
        self.duration = SPToastDurationNormal;
        self.gravity = SPToastGravityDefault;
    }

    return self;
}

- (instancetype)initWithSettings:(SPToastSettings *)someSettings
{
    //
    // Check parameter.
    //

    NSAssert(
    [someSettings isKindOfClass:[SPToastSettings class]],
    @"Expecting someSettings parameter to be kind of class %@.",
    NSStringFromClass([someSettings class]));

    //
    // Initialise.
    //

    if (self) {
        self.gravity = someSettings.gravity;
        self.duration = someSettings.duration;
        self.imagesMutable = someSettings.imagesMutable;

        if (someSettings.positionIsSet) {
            self.position = someSettings.position;
        }
    }

    return self;
}

+ (SPToastSettings *)toastSettings
{
    return [[self alloc] initWithSettings:[self sharedSettings]];
}

#pragma mark  
#pragma mark Getting the Shared Instance

+ (SPToastSettings *)sharedSettings
{
    static SPToastSettings *sharedSettings = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^(void) {

		sharedSettings = [SPToastSettings new];

		sharedSettings.gravity = SPToastGravityCenter;
		sharedSettings.duration = SPToastDurationShort;
    });

    return sharedSettings;
}


#pragma mark  
#pragma mark Managing Images

- (UIImage *)imageForType:(SPToastType)aType
{
    return self.imagesMutable[@(aType)];
}

- (void)setImage:(UIImage *)anImage forType:(SPToastType)aType
{
    //
    // Check parameters.
    //

    // TODO: Use stringification macros once merged with branch containing these.

    NSAssert(
    !anImage || [anImage isKindOfClass:[UIImage class]],
    @"Expecting anImage parameter to be kind of class UIImage.");

    NSAssert(
    SPToastTypeMin <= aType && SPToastTypeMax >= aType,
    @"aType parameter contains invalid SPToastType value.");

    NSAssert(
    aType != SPToastTypeNone,
    @"This should not be used, internal use only (to force no image).");

    //
    // Set image for type.
    //

    if (anImage) {
        [self.imagesMutableLazy setObject:anImage forKey:@(aType)];

    } else {
        [self.imagesMutable removeObjectForKey:@(aType)];
    }
}

#pragma mark  
#pragma mark NSObject: Creatingy, Copying, and Deallocating Objects

- (id)copyWithZone:(NSZone *)zone
{
    SPToastSettings *const copy = [[[self class] alloc] initWithSettings:self];
    return copy;
}

@end

#pragma mark  
