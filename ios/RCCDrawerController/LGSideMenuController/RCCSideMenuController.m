//
//  RCCSideMenuController.m
//  ReactNativeNavigation
//
//  Created by Simon Mitchell on 18/02/2017.
//  Copyright © 2017 artal. All rights reserved.
//

#import "RCCSideMenuController.h"
#import "RCCDrawerController.h"
#import "RCCViewController.h"
#import "RCCDrawerHelper.h"
#import "RCTConvert.h"
#import "RCCManagerModule.h"

@interface RCCSideMenuController ()

@end

@implementation RCCSideMenuController

@synthesize overlayButton = _overlayButton, drawerStyle = _drawerStyle;

- (instancetype)initWithProps:(NSDictionary *)props children:(NSArray *)children globalProps:(NSDictionary*)globalProps bridge:(RCTBridge *)bridge {

    if ([children count] < 1) return nil;

    UIViewController *centerVC = [RCCViewController controllerWithLayout:children[0] globalProps:props bridge:bridge];
    UIViewController *leftVC = nil;
    UIViewController *rightVC = nil;

    // left
    NSString *componentLeft = props[@"componentLeft"];
    if (componentLeft)  {
        leftVC = [[RCCViewController alloc] initWithComponent:componentLeft passProps:props[@"passPropsLeft"] navigatorStyle:nil globalProps:props bridge:bridge];
    }

    // right
    NSString *componentRight = props[@"componentRight"];
    if (componentRight) {
        rightVC = [[RCCViewController alloc] initWithComponent:componentRight passProps:props[@"passPropsRight"] navigatorStyle:nil globalProps:props bridge:bridge];
    }
    
    self = [super initWithRootViewController:centerVC leftViewController:leftVC rightViewController:rightVC];

    if (!self) return nil;

    self.drawerStyle = props[@"style"];
    self.delegate = self;
    
    [self setAnimationType:props[@"animationType"]];
    [self setStyle];

    return self;
}

- (void)performAction:(NSString *)performAction actionParams:(NSDictionary *)actionParams bridge:(RCTBridge *)bridge {
    LGSideMenuSide side = LGSideMenuSideLeft;
    
    if ([actionParams[@"side"] isEqualToString:@"right"]) side = LGSideMenuSideRight;
    
    //open
    if ([performAction isEqualToString:@"open"]) {
        
        if (side == LGSideMenuSideLeft) {
            [self showLeftViewAnimated:nil];
        } else {
            [self showRightViewAnimated:nil];
        }
        return;
    }
    
    // close
    if ([performAction isEqualToString:@"close"]) {
        
        if (side == LGSideMenuSideLeft) {
            [self hideLeftViewAnimated:nil];
        } else {
            [self hideRightViewAnimated:nil];
        }
        return;
    }
    
    //toggle
    if ([performAction isEqualToString:@"toggle"]) {
        [self setStyle:side];
        
        if (side == LGSideMenuSideLeft) {
            if (self.leftViewHidden) {
                [self showLeftViewAnimated:nil];
            } else {
                [self hideLeftViewAnimated:nil];
            }
        } else {
            if (self.rightViewHidden) {
                [self showRightViewAnimated:nil];
            } else {
                [self hideRightViewAnimated:nil];
            }
        }
        return;
    }
    
    // setStyle
    if ([performAction isEqualToString:@"setStyle"])
    {
        if (actionParams[@"animationType"]) {
            NSString *animationTypeString = actionParams[@"animationType"];
            
            [self setAnimationType:animationTypeString];
        }
        return;
    }
    
    // Toggle drawer gesture
    if ([performAction isEqualToString:@"toggleGestureEnabled"]) {
        
        if ([actionParams objectForKey:@"enabled"] && [[actionParams objectForKey:@"enabled"] isKindOfClass:[NSNumber class]]) {
            
            BOOL enabled = [[actionParams objectForKey:@"enabled"] boolValue];
            if (side == LGSideMenuSideLeft) {
                [self setLeftViewSwipeGestureEnabled:enabled];
            } else {
                [self setRightViewSwipeGestureEnabled:enabled];
            }
        } else {
            
            if (side == LGSideMenuSideLeft) {
                [self setLeftViewSwipeGestureEnabled:!self.leftViewSwipeGestureEnabled];
            } else {
                [self setRightViewSwipeGestureEnabled:!self.rightViewSwipeGestureEnabled];
            }
        }
    }
}

-(void)setStyle {
    
    [self setStyle:LGSideMenuSideLeft];
    [self setStyle:LGSideMenuSideRight];
    
    NSString *contentOverlayColor = self.drawerStyle[@"contentOverlayColor"];
    if (contentOverlayColor)
    {
        UIColor *color = contentOverlayColor != (id)[NSNull null] ? [RCTConvert UIColor:contentOverlayColor] : nil;
        self.rootViewCoverColorForLeftView = color;
        self.rootViewCoverColorForRightView = color;
    }
    
    NSNumber *contentOverlayOpacity = self.drawerStyle[@"contentOverlayOpacity"];
    if (contentOverlayOpacity)
    {
        self.rootViewCoverAlphaForLeftView = contentOverlayOpacity.floatValue;
        self.rootViewCoverAlphaForRightView = contentOverlayOpacity.floatValue;
    }
    
    UIImage *backgroundImage = nil;
    id icon = self.drawerStyle[@"backgroundImage"];
    UIWindow *appDelegateWindow = [[[UIApplication sharedApplication] delegate] window];
    self.rootViewController.view.backgroundColor = appDelegateWindow.backgroundColor;
    
    if (icon)
    {
        backgroundImage = [RCTConvert UIImage:icon];
        if (backgroundImage) {
            backgroundImage = [RCCDrawerHelper imageWithImage:backgroundImage scaledToSize:appDelegateWindow.bounds.size];
            [appDelegateWindow setBackgroundColor:[UIColor colorWithPatternImage:backgroundImage]];
        }
    }
}

- (void)setStyle:(LGSideMenuSide)side {
    if (side == LGSideMenuSideLeft && !self.leftViewController) return;
    if (side == LGSideMenuSideRight && !self.rightViewController) return;
    
    CGRect sideBarFrame = self.view.frame;
    
    switch (side) {
        case LGSideMenuSideLeft:
        {
            NSNumber *leftDrawerWidth = self.drawerStyle[@"leftDrawerWidth"];
            if (!leftDrawerWidth) leftDrawerWidth = [NSNumber numberWithInteger:DRAWER_DEFAULT_WIDTH_PERCENTAGE];
            self.leftViewWidth = self.view.bounds.size.width * MIN(1, (leftDrawerWidth.floatValue/100.0));
            sideBarFrame.size.width = self.view.bounds.size.width * MIN(1, (leftDrawerWidth.floatValue/100.0));
            self.leftViewController.view.frame = sideBarFrame;
        }
            break;
        case LGSideMenuSideRight:
        {
            NSNumber *rightDrawerWidth = self.drawerStyle[@"rightDrawerWidth"];
            if (!rightDrawerWidth) rightDrawerWidth = [NSNumber numberWithInteger:DRAWER_DEFAULT_WIDTH_PERCENTAGE];
            self.rightViewWidth = self.view.bounds.size.width * MIN(1, (rightDrawerWidth.floatValue/100.0));
            sideBarFrame.size.width = self.view.bounds.size.width * MIN(1, (rightDrawerWidth.floatValue/100.0));
            self.rightViewController.view.frame = sideBarFrame;
        }
            
        default:
            break;
    }
}

-(void)setAnimationType:(NSString*)type {
    if ([type isEqualToString:@"slide-above"]) {
        self.leftViewPresentationStyle = LGSideMenuPresentationStyleSlideAbove;
        self.rightViewPresentationStyle = LGSideMenuPresentationStyleSlideAbove;
    }
    else if ([type isEqualToString:@"slide-below"]) {
        self.leftViewPresentationStyle = LGSideMenuPresentationStyleSlideBelow;
        self.rightViewPresentationStyle = LGSideMenuPresentationStyleSlideBelow;
    }
    else if ([type isEqualToString:@"slide-from-big"]) {
        self.leftViewPresentationStyle = LGSideMenuPresentationStyleScaleFromBig;
        self.rightViewPresentationStyle = LGSideMenuPresentationStyleScaleFromBig;
    }
    else if ([type isEqualToString:@"scale-from-little"]) {
        self.leftViewPresentationStyle = LGSideMenuPresentationStyleScaleFromLittle;
        self.rightViewPresentationStyle = LGSideMenuPresentationStyleScaleFromLittle;
    }
    else {
        self.leftViewPresentationStyle = LGSideMenuPresentationStyleSlideAbove;
        self.rightViewPresentationStyle = LGSideMenuPresentationStyleSlideAbove;
    }
}

@end
