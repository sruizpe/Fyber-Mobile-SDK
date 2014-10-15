//
//  SPToast.h
//  SPToast (iToast)
//
//  Created by Diallo Mamadou Bobo on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, SPToastGravity) {
    SPToastGravityBottom,
    SPToastGravityCenter,
    SPToastGravityTop,
    SPToastGravityDefault = SPToastGravityTop,
    SPToastGravityMin = SPToastGravityBottom,
    SPToastGravityMax = SPToastGravityTop
};

typedef NS_ENUM(NSUInteger, SPToastType) {
    SPToastTypeError,
    SPToastTypeInfo,

    //!Toast won't use a background image.
    SPToastTypeNone,
    SPToastTypeNotice,
    SPToastTypeWarning,
    SPToastTypeDefault = SPToastTypeNone,
    SPToastTypeMin = SPToastTypeDefault,
    SPToastTypeMax = SPToastTypeWarning,
};


extern NSTimeInterval const SPToastDurationLong;
extern NSTimeInterval const SPToastDurationShort;
extern NSTimeInterval const SPToastDurationNormal;


@class SPToastSettings;


#pragma mark  

@interface SPToast : NSObject

#pragma mark  
#pragma mark Public Properties -

@property (nonatomic, copy, readonly) NSString *text;

#pragma mark  
#pragma mark  
#pragma mark Public Methods -

#pragma mark  
#pragma mark Enqueuing Toasts

/*!
    \brief Returns the currently dequeued (and shown) toast.
    
    After the dequeued toast is hidden the value returned by this method changes
    to the next toast in the queue or to \c nil if there is no next toast. 
*/
+ (SPToast *)dequeuedToast;

/*!
    \brief Enqueues a toast to be shown.
    \param aType The type of the toast to be enqueued.
    \param aText The text of the toast to be enqueued.
    \param optionalSettings An SPToastSettings instance defining custom settings
        or \c nil if the shared settings are to be used.
    \return The enqueued toast.
    \see SPToastSettings
    
    The enqueued toast might right be dequeued again and shown right away if the
    queue is empty.
*/
+ (SPToast *)enqueueToastOfType:(SPToastType)aType
                       withText:(NSString *)aText
                       settings:(SPToastSettings *)optionalSettings;

+ (SPToast *)enqueueToastWithText:(NSString *)aText;

#pragma mark  
#pragma mark Showing Toasts

/*!
    \brief Shows a toast.
    \param aType The type of the toast to be shown.
    \param aText The text of the toast to be shown.
    \param optionalSettings An SPToastSettings instance defining custom settings
        or \c nil if the shared settings are to be used.
    \return The shown toast.
    \see SPToastSettings
    
    The toast returned is shown no matter what. It might overlap with other 
    toasts previously shown using this method or with a dequeued toast.
*/
+ (SPToast *)showToastOfType:(SPToastType)aType
                    withText:(NSString *)aText
                    settings:(SPToastSettings *)optionalSettings;

+ (SPToast *)showToastWithText:(NSString *)aText;

#pragma mark  
#pragma mark Hiding Toasts

- (void)hide;

@end


#pragma mark  
#pragma mark  
#pragma mark  

@interface SPToastSettings : NSObject<NSCopying>

#pragma mark  
#pragma mark Public Properties -

@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) SPToastGravity gravity;
@property (nonatomic, assign) CGFloat offsetLeft;
@property (nonatomic, assign) CGFloat offsetTop;
@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign, readonly) BOOL positionIsSet;

#pragma mark  
#pragma mark  
#pragma mark Public Methods -

#pragma mark  
#pragma mark Initialising

- (instancetype)init;
- (instancetype)initWithSettings:(SPToastSettings *)someSettings;
+ (SPToastSettings *)toastSettings;

#pragma mark  
#pragma mark Getting the Shared Instance

+ (SPToastSettings *)sharedSettings;

#pragma mark  
#pragma mark Managing Images

/*!
    \brief Returns the image used as backgound for the specified toast type.
    \param aType The toast type for which to return the image.
    \return The image or \c nil if no image is set for the type.
*/
- (UIImage *)imageForType:(SPToastType)aType;

/*!
    \brief Sets the background image for the specified toast type.
    \param anImage The image to be set. If \c nil a possibly previously set
        image will be replaced.
    \param aType The toast type for which the background image is to be set.
        May not be \c SPToastTypeNone.
    \remarks You cannot set SPToastTypeNone since this type denotes a toast
        without a background.
*/
- (void)setImage:(UIImage *)anImage forType:(SPToastType)aType;

@end

#pragma mark  
