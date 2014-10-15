//
//  SPCloseButton.m
//  SPVideoPlayer
//
//  Created by Daniel Barden on 29/01/14.
//  Copyright (c) 2014 SponsorPay GmbH. All rights reserved.
//

#import "SPCloseButton.h"
#import <QuartzCore/QuartzCore.h>

#define IS_RETINA() [[UIScreen mainScreen] scale] == 2.0


@interface SPCloseButton ()

@property (nonatomic, assign, readwrite) CGFloat lineWidth;

@property (nonatomic, strong) CAShapeLayer *closeCrossLayer;
@property (nonatomic, strong) CAShapeLayer *backgroundLayer;
@property (nonatomic, strong) UIView *containerView;

@end

@implementation SPCloseButton

- (id)initWithFrame:(CGRect)frame paddingInsets:(UIEdgeInsets)insets
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _paddingInsets = insets;
        [self setupView];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame paddingInsets:UIEdgeInsetsZero];
}

- (void)setupView
{
    self.lineWidth = IS_RETINA() ? 0.7f : 1.5f;

    // Container where the Bezier Path is drwarn. This view will be rotated to create the X
    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.containerView.userInteractionEnabled = NO;
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self addSubview:self.containerView];

    // Circle shape
    self.backgroundLayer = [CAShapeLayer layer];
    CGColorRef strokeColor = [UIColor colorWithWhite:1 alpha:0.7].CGColor;
    self.backgroundLayer.strokeColor = strokeColor;
    self.backgroundLayer.lineWidth = self.lineWidth;
    self.backgroundLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;

    //  The X shape of the close button
    self.closeCrossLayer = [CAShapeLayer layer];
    self.closeCrossLayer.lineWidth = self.lineWidth;
    self.closeCrossLayer.strokeColor = strokeColor;


    [self.containerView.layer addSublayer:self.backgroundLayer];
    [self.containerView.layer addSublayer:self.closeCrossLayer];
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    // rotate the container view to create the X from a + shape
    CGAffineTransform rotation = CGAffineTransformMakeRotation(M_PI_4);
    [self.containerView setTransform:rotation];
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];


    CGPoint centerPoint = CGPointMake(CGRectGetWidth(rect) / 2, CGRectGetHeight(rect) / 2);
    CGRect drawableArea = UIEdgeInsetsInsetRect(rect, self.paddingInsets);
    CGFloat radius = drawableArea.size.width / 2;


    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:centerPoint
                                                              radius:radius
                                                          startAngle:-(M_PI / 2)
                                                            endAngle:(3 * M_PI) / 2
                                                           clockwise:YES];

    self.backgroundLayer.path = circlePath.CGPath;


    // The X of the close button
    CGFloat xLengthRatio = 0.5;

    UIBezierPath *xPath = [UIBezierPath bezierPath];
    [xPath moveToPoint:centerPoint];
    [xPath addLineToPoint:CGPointMake(centerPoint.x, centerPoint.y + (radius * xLengthRatio))];
    [xPath moveToPoint:centerPoint];
    [xPath addLineToPoint:CGPointMake(centerPoint.x, centerPoint.y - (radius * xLengthRatio))];
    [xPath moveToPoint:centerPoint];
    [xPath addLineToPoint:CGPointMake(centerPoint.x + (radius * xLengthRatio), centerPoint.y)];
    [xPath moveToPoint:centerPoint];
    [xPath addLineToPoint:CGPointMake(centerPoint.x - (radius * xLengthRatio), centerPoint.y)];
    [xPath moveToPoint:centerPoint];
    [xPath closePath];

    self.closeCrossLayer.path = xPath.CGPath;
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted) {
        self.backgroundLayer.fillColor = [UIColor colorWithWhite:127 / 255.0 alpha:0.5].CGColor;
    } else {
        self.backgroundLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
    }
    [super setHighlighted:highlighted];
}
@end
