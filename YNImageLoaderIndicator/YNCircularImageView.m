//
//  YNCircularLoaderView.m
//  YNImageLoaderIndicator
//
//  Created by qiyun on 16/6/14.
//  Copyright © 2016年 qiyun. All rights reserved.
//

#import "YNCircularImageView.h"
#import "SDWebImage/UIImageView+WebCache.h"

@interface YNCircularLoaderView ()

@property (nonatomic) CGFloat   progress;

@end

@implementation YNCircularLoaderView{
    
    CAShapeLayer    *shapeLayer;
    CGFloat         radius;
}

#pragma mark    -   private method

- (void)reveal{
    
    self.backgroundColor = [UIColor clearColor];
    self.progress = 1;
    [shapeLayer removeAnimationForKey:@"strokeEnd"];
    [shapeLayer removeFromSuperlayer];
    self.superview.layer.mask = shapeLayer;
    
    CGPoint center = CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMidY(self.bounds));
    double finalRadius = sqrt((center.x * center.x) + (center.y * center.y));
    double radiusInset = finalRadius - radius;
    CGRect outerRect = CGRectInset([self circleFrame], -radiusInset, -radiusInset);
    CGPathRef toPath = [UIBezierPath bezierPathWithRect:outerRect].CGPath;
    
    CGPathRef fromPath = shapeLayer.path;
    CGFloat fromLineWidth = shapeLayer.lineWidth;
    
    {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        shapeLayer.lineWidth = 2 * finalRadius;
        shapeLayer.path = toPath;
        [CATransaction commit];
        
        CABasicAnimation *lineWidthAnimation = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
        lineWidthAnimation.fromValue = @(fromLineWidth);
        lineWidthAnimation.toValue = @(2 * finalRadius);
        CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        pathAnimation.fromValue = (__bridge id _Nullable)(fromPath);
        pathAnimation.toValue = (__bridge id _Nullable)(toPath);
        
        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = 1;
        animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animationGroup.animations = @[pathAnimation, lineWidthAnimation];
        animationGroup.delegate = self;
        [shapeLayer addAnimation:animationGroup forKey:@"strokeWidth"];
    }
}

- (CGRect)circleFrame{
    
    CGRect circleFrame = CGRectMake(0, 0, 2*radius, 2*radius);
    circleFrame.origin.x = CGRectGetMidX(shapeLayer.bounds) - CGRectGetMidX(circleFrame);
    circleFrame.origin.y = CGRectGetMidY(shapeLayer.bounds) - CGRectGetMidY(circleFrame);
    return circleFrame;
}


- (UIBezierPath *)circlePath{
    
    /* 画圆 */
    //return [UIBezierPath bezierPathWithOvalInRect:[self circleFrame]];
    
    /* 画矩形 */
    return [UIBezierPath bezierPathWithRect:[self circleFrame]];
}


- (CGFloat)progress{
    
    return shapeLayer.strokeEnd;
}

- (void)setProgress:(CGFloat)progress{
    
    //NSLog(@"progress = %f",progress);
    
    if (progress > 1)       shapeLayer.strokeEnd = 1;
    else if (progress < 0)  shapeLayer.strokeEnd = 0;
    else                    shapeLayer.strokeEnd = progress;
}

#pragma mark    -   life cycle

- (id)initWithFrame:(CGRect)frame{
    
    if (self == [super initWithFrame:frame]) {
        
        radius = 20.0f;
        shapeLayer = [[CAShapeLayer alloc] init];
        shapeLayer.frame = self.bounds;
        shapeLayer.lineWidth = 2;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        shapeLayer.strokeColor = [UIColor redColor].CGColor;
        [self.layer addSublayer:shapeLayer];
        self.backgroundColor = [UIColor whiteColor];
        self.progress = 0;
    }
    return self;
}

- (void)layoutSubviews{
    
    [super layoutSubviews];
    
    shapeLayer.frame = self.bounds;
    shapeLayer.path = [self circlePath].CGPath;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    
    self.superview.layer.mask = nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end


@implementation YNCircularImageView{
    
    YNCircularLoaderView *progressIndicatorView;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    
    if (self == [super initWithCoder:aDecoder]) {
        
        [self subViewBringWithCurrent];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame{
    
    if (self == [super initWithFrame:frame]) {
        
        [self subViewBringWithCurrent];
    }
    return self;
}

- (void)subViewBringWithCurrent{
    
    progressIndicatorView = [[YNCircularLoaderView alloc] initWithFrame:CGRectZero];
    progressIndicatorView.frame = self.bounds;
    progressIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self addSubview:progressIndicatorView];
    
    [self sd_setImageWithURL:[NSURL URLWithString:@"http://www.raywenderlich.com/wp-content/uploads/2015/02/mac-glasses.jpeg"]
            placeholderImage:nil options:SDWebImageCacheMemoryOnly
                    progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                        
                        [progressIndicatorView setProgress:(CGFloat)receivedSize/expectedSize];
                        
                    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                        
                        [progressIndicatorView reveal];
                    }];
}

@end
