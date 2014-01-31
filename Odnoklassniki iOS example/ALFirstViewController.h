//
//  ALFirstViewController.h
//  Odnoklassniki iOS example
//
//  Created by Артем Лобачев on 28.01.14.
//  Copyright (c) 2014 Артем Лобачев. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OKRequest.h"
#import "OKSession.h"
#import "Odnoklassniki.h"
#import "ALFriend.h"

static NSString * appID = @"";
static NSString * appSecret = @"";
static NSString * appKey = @"";

@interface ALFirstViewController : UIViewController <OKSessionDelegate, OKRequestDelegate,UITableViewDelegate, UITableViewDataSource>
{
    Odnoklassniki *_api;
    NSMutableArray *friends;
}


@end
