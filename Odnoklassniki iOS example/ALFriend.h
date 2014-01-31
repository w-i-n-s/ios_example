//
//  ALFriend.h
//  Odnoklassniki iOS example
//
//  Created by Артем Лобачев on 31.01.14.
//  Copyright (c) 2014 Артем Лобачев. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALFriend : NSObject
@property (copy) NSString *name;
@property (copy) NSString *surname;
@property (copy) NSString *uid;
@property (copy) NSString *pic_1Url;
@property bool isOnline;
- (id) initWithUid:(NSString*) userId;
@end
