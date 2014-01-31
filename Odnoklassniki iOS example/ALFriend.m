//
//  ALFriend.m
//  Odnoklassniki iOS example
//
//  Created by Артем Лобачев on 31.01.14.
//  Copyright (c) 2014 Артем Лобачев. All rights reserved.
//

#import "ALFriend.h"

@implementation ALFriend
@synthesize name,surname,uid,isOnline,pic_1Url;
- (id)init {
    @throw [NSException exceptionWithName:@"Wronng inin"
                                   reason:@"ALFriend must be initialized with initWithUid method"
                                 userInfo:nil];
}

- (id) initWithUid:(NSString*) userId {
    self = [super init];
    if (self) {
        self.uid = userId;
    }
    
    return self;
}

@end
