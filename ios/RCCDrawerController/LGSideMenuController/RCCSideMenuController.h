//
//  RCCSideMenuController.h
//  ReactNativeNavigation
//
//  Created by Simon Mitchell on 18/02/2017.
//  Copyright © 2017 artal. All rights reserved.
//

#import "LGSideMenuController.h"
#import "RCCDrawerProtocol.h"

typedef NS_ENUM(NSInteger,LGSideMenuSide){
    LGSideMenuSideNone = 0,
    LGSideMenuSideLeft,
    LGSideMenuSideRight,
};


@interface RCCSideMenuController : LGSideMenuController <RCCDrawerDelegate>

@end
