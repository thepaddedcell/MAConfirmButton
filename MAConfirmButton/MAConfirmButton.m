//
//  MAConfirmButton.m
//
//  Created by Mike on 11-03-28.
//  Copyright 2011 Mike Ahmarani. All rights reserved.
//

#import "MAConfirmButton.h"
#import "UIColor-Expanded.h"

#define kHeight 26.0
#define kPadding 20.0
#define kFontSize 14.0

@interface MAConfirmButton ()

@property (nonatomic, retain) UIColor *tint;
@property (nonatomic, assign) BOOL buttonSelected;
@property (nonatomic, assign) BOOL confirmed;
@property (nonatomic, retain) CALayer *colorLayer;
@property (nonatomic, retain) CALayer *darkenLayer;
@property (nonatomic, retain) UIButton *cancelOverlay;

- (void)toggle;
- (void)setupLayers;
- (void)cancel;
- (void)lighten;
- (void)darken;

@end

@implementation MAConfirmButton

- (void)dealloc {
    [_title release];
    [_confirm release];
    [_disabled release];
    [_tint release];
    [super dealloc];
}

+ (MAConfirmButton *)buttonWithTitle:(NSString *)titleString confirm:(NSString *)confirmString {
    MAConfirmButton *button = [[[super alloc] initWithTitle:titleString confirm:confirmString] autorelease];	
    return button;
}

+ (MAConfirmButton *)buttonWithDisabledTitle:(NSString *)disabledString {
    MAConfirmButton *button = [[[super alloc] initWithDisabledTitle:disabledString] autorelease];	
    return button;
}

- (id)initWithDisabledTitle:(NSString *)disabledString {
    self = [super initWithFrame:CGRectZero];
    if (self != nil) {
        _disabled = [disabledString retain];

        _toggleAnimation = MAConfirmButtonToggleAnimationLeft;

        self.layer.needsDisplayOnBoundsChange = YES;
        self.tint = [UIColor colorWithWhite:0.85 alpha:1];

        CGSize size = [self.title sizeWithAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize]}];
        CGRect r = self.frame;
        r.size.height = kHeight;
        r.size.width = size.width+kPadding;
        self.frame = r;

        [self setTitle:self.disabled forState:UIControlStateNormal];
        [self setTitleColor:self.tint forState:UIControlStateNormal];
        
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:kFontSize];

        [self setupLayers];
    }	
    return self;	
}

- (id)initWithTitle:(NSString *)titleString confirm:(NSString *)confirmString {
    self = [super initWithFrame:CGRectZero];
    if (self != nil) {
        self.title = [titleString retain];
        self.confirm = [confirmString retain];

        self.toggleAnimation = MAConfirmButtonToggleAnimationLeft;
        self.tint = [UIColor colorWithRed:0.220 green:0.357 blue:0.608 alpha:1];

        self.layer.needsDisplayOnBoundsChange = YES;

        CGSize size = [self.title sizeWithAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize]}];
        CGRect r = self.frame;
        r.size.height = kHeight;
        r.size.width = size.width+kPadding;
        self.frame = r;

        [self setTitle:self.title forState:UIControlStateNormal];
        [self setTitleColor:self.tint forState:UIControlStateNormal];

        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:kFontSize];

        [self setupLayers];
    }	
    return self;
}

- (void)toggle {
    if (self.userInteractionEnabled) {
        self.userInteractionEnabled = NO;
        self.titleLabel.alpha = 0;

        CGSize size;

        if (self.disabled) {
            [self setTitle:self.disabled forState:UIControlStateNormal];
            [self setTitleColor:self.tint forState:UIControlStateNormal];
            size = [self.disabled sizeWithAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize]}];
        } else if (self.buttonSelected) {
            [self setTitle:self.confirm forState:UIControlStateNormal];
            size = [self.confirm sizeWithAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize]}];
        } else {
            [self setTitle:self.title forState:UIControlStateNormal];
            size = [self.title sizeWithAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:kFontSize]}];
        }

        size.width += kPadding;
        float offset = size.width - self.frame.size.width;

        [CATransaction begin];
        [CATransaction setAnimationDuration:0.25];
        [CATransaction setCompletionBlock:^{
            //Readjust button frame for new touch area, move layers back now that animation is done

            CGRect frameRect = self.frame;
            switch(self.toggleAnimation) {
                case MAConfirmButtonToggleAnimationLeft:
                    frameRect.origin.x = frameRect.origin.x - offset;
                    break;
                case MAConfirmButtonToggleAnimationRight:
                    break;
                case MAConfirmButtonToggleAnimationCenter:
                    frameRect.origin.x = frameRect.origin.x - offset/2.0;
                    break;
                default:
                    break;
            }
            frameRect.size.width = frameRect.size.width + offset;
            self.frame = frameRect;

            [CATransaction setDisableActions:YES];
            [CATransaction setCompletionBlock:^{
                self.userInteractionEnabled = YES;
            }];
            for (CALayer *layer in self.layer.sublayers) {
                CGRect rect = layer.frame;
                switch(self.toggleAnimation) {
                    case MAConfirmButtonToggleAnimationLeft:
                        rect.origin.x = rect.origin.x+offset;
                        break;
                    case MAConfirmButtonToggleAnimationRight:
                        break;
                    case MAConfirmButtonToggleAnimationCenter:
                        rect.origin.x = rect.origin.x+offset/2.0;
                        break;
                    default:
                        break;
                }

                layer.frame = rect;
            }
            [CATransaction commit];

            self.titleLabel.alpha = 1;
            [self setNeedsLayout];
        }];

        UIColor *greenColor = [UIColor colorWithRed:0.439 green:0.741 blue:0.314 alpha:1.];

        //Animate color change
        CABasicAnimation *colorAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
        colorAnimation.removedOnCompletion = NO;
        colorAnimation.fillMode = kCAFillModeForwards;
        
        UIColor* titleColor;
        
        if (self.disabled) {
            colorAnimation.fromValue = (id)greenColor.CGColor;
            colorAnimation.toValue = (id)[UIColor colorWithWhite:0.85 alpha:1].CGColor;
            titleColor = [UIColor colorWithWhite:0.85 alpha:1];
        } else {
            colorAnimation.fromValue = self.buttonSelected ? (id)self.tint.CGColor : (id)greenColor.CGColor;
            colorAnimation.toValue = self.buttonSelected ? (id)greenColor.CGColor : (id)self.tint.CGColor;
            titleColor = self.buttonSelected ? greenColor : self.tint;
        }
        [self setTitleColor:titleColor forState:UIControlStateNormal];
        
        [_colorLayer addAnimation:colorAnimation forKey:@"colorAnimation"];

        //Animate layer scaling
        for (CALayer *layer in self.layer.sublayers) {
        CGRect rect = layer.frame;

        switch(self.toggleAnimation) {
            case MAConfirmButtonToggleAnimationLeft:
                rect.origin.x = rect.origin.x-offset;
                break;
            case MAConfirmButtonToggleAnimationRight:
                break;
            case MAConfirmButtonToggleAnimationCenter:
                rect.origin.x = rect.origin.x-offset/2.0;
                break;
            default:
                break;
        }
        rect.size.width = rect.size.width+offset;
        layer.frame = rect;
        }

        [CATransaction commit];
        [self setNeedsDisplay];
    }
}

- (void)setupLayers {
  
    self.colorLayer = [CALayer layer];
    self.colorLayer.backgroundColor = [[UIColor clearColor] CGColor];
    self.colorLayer.frame = CGRectMake(0, 1, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)-2);
    self.colorLayer.borderColor = self.tint.CGColor;
    self.colorLayer.borderWidth = 1.0;
    self.colorLayer.cornerRadius = 4.0;
    self.colorLayer.needsDisplayOnBoundsChange = YES;

    [self.layer addSublayer:self.colorLayer];
    [self bringSubviewToFront:self.titleLabel];
}

- (void)setButtonSelected:(BOOL)buttonSelected
{
    _buttonSelected = buttonSelected;
    self.selected = buttonSelected;
    [self toggle];
}

- (void)disableWithTitle:(NSString *)disabledString {
    self.disabled = [disabledString retain];    
    [self toggle];	
}

- (void)setTitle:(NSString *)title andConfirm:(NSString*)confirm
{
    self.title = title;
    self.confirm = confirm;
    [self setNeedsDisplay];
}

- (void)setAnchor:(CGPoint)anchor {
    //Top-right point of the view (MUST BE SET LAST)
    CGRect rect = self.frame;
    rect.origin = CGPointMake(anchor.x - rect.size.width, anchor.y);
    self.frame = rect;
}

- (void)setTintColor:(UIColor *)color {
    self.tint = [UIColor colorWithHue:color.hue saturation:color.saturation+0.15 brightness:color.brightness alpha:1];
    self.colorLayer.borderColor = self.tint.CGColor;
    [self setTitleColor:self.tint forState:UIControlStateNormal];
    [self setNeedsDisplay];
}

- (void)darken {
    self.darkenLayer = [CALayer layer];
    self.darkenLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    self.darkenLayer.borderColor = [UIColor colorWithWhite:0 alpha:0.2].CGColor;
    self.darkenLayer.cornerRadius = 4.0;
    self.darkenLayer.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:self.darkenLayer];
}

- (void)lighten {
    if (self.darkenLayer) {
        [self.darkenLayer removeFromSuperlayer];
        self.darkenLayer = nil;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    if (!self.disabled && !self.confirmed && self.userInteractionEnabled) {
        [self darken];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  
    if (!self.disabled && !self.confirmed && self.userInteractionEnabled) {
        if (!CGRectContainsPoint(self.frame, [[touches anyObject] locationInView:self.superview])) { //TouchUpOutside (Cancelled Touch)
            [self lighten];
            [super touchesCancelled:touches withEvent:event];
        } else if (self.buttonSelected) {
            [self lighten];
            self.confirmed = YES;
            [self.cancelOverlay removeFromSuperview];
            self.cancelOverlay = nil;
            [super touchesEnded:touches withEvent:event];
        } else {
            [self lighten];		
            self.buttonSelected = YES;
            if (!self.cancelOverlay) {
                self.cancelOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
                [self.cancelOverlay setFrame:CGRectMake(0, 0, 1024, 1024)];
                [self.cancelOverlay addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchDown];
                [self.superview addSubview:self.cancelOverlay];
            }
            [self.superview bringSubviewToFront:self];
        }
    }
    
}

- (void)cancel {
    if (self.cancelOverlay && self.userInteractionEnabled) {
        [self.cancelOverlay removeFromSuperview];
        self.cancelOverlay = nil;
    }	
    self.buttonSelected = NO;
}


@end
