//
//  ALFirstViewController.m
//  Odnoklassniki iOS example
//
//  Created by Артем Лобачев on 28.01.14.
//  Copyright (c) 2014 Артем Лобачев. All rights reserved.
//

#import "ALFirstViewController.h"
#import "Odnoklassniki.h"

@interface ALFirstViewController ()
@property (weak, nonatomic) IBOutlet UILabel *sessionStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *authButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *surnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *countryTextField;
@property (weak, nonatomic) IBOutlet UIImageView *photo;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation ALFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.authButton addTarget:self action:@selector(loginButtonClick:) forControlEvents:UIControlEventTouchDown];
    // API initialization
    // инициализация API
	self->_api = [[Odnoklassniki alloc] initWithAppId:appID andAppSecret:appSecret andAppKey:appKey andDelegate:self];
    // if access_token is valid
    // если access_token действителен
    if(self->_api.isSessionValid) {
        [self.sessionStatusLabel setText:@"Logged in"];
        [self.authButton setTitle:NSLocalizedString(@"Logout", nil) forState:UIControlStateNormal];
        [self okDidLogin];
    } else {
        [self.sessionStatusLabel setText:@"Not logged in"];
        [self.authButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
        [self->_api refreshToken];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - API requests

/*
* API request without params.
* Запрос к API без параметров.
*/
- (void)getFriends{
    OKRequest *newRequest = [Odnoklassniki requestWithMethodName:@"friends.get"
													   andParams:nil
												   andHttpMethod:@"GET"
													 andDelegate:self];
    [newRequest load];
}

/*
 * API request with params.
 * Запрос к API с параметрами.
 */
- (void)getUserInfo{
    @autoreleasepool {
        [self.authButton setTitle:NSLocalizedString(@"Logout", nil) forState:UIControlStateNormal];
        OKRequest *newRequest = [Odnoklassniki requestWithMethodName:@"users.getCurrentUser"
                                                           andParams:[NSMutableDictionary dictionaryWithDictionary:@{@"fields": @"first_name,last_name,location,pic_1"}]
                                                       andHttpMethod:@"GET"
                                                         andDelegate:self];
        [newRequest load];
    }
    
}

#pragma mark - Odnoklassniki Delegate methods

/*
* Method will be called after success login ([_api authorize:])
* Метод будет вызван после успешной авторизации ([_api authorize:])
*/

-(void)okDidLogin {
    [self.sessionStatusLabel setText:@"Logged in"];
    [self getUserInfo];
    [self getFriends];
}

/*
 * Method will be called if login faild (cancelled == YES if user cancelled login, NO otherwise)
 * Метод будет вызван, если при авторизации произошла ошибка (cancelled == YES если пользователь прервал авторизацию, NO во всех остальных случаях)
*/
-(void)okDidNotLogin:(BOOL)canceled {

}

/*
 * Method will be called if login faild and server returned an error
 * Метод будет вызван, если сервер вернул ошибку авторизации
*/
-(void)okDidNotLoginWithError:(NSError *)error {

}

/*
 * Method will be called if [_api refreshToken] called and new access_token was got
 * Метод будет вызван в случае, если вызван [_api refreshToken] и получен новый access_token
*/
-(void)okDidExtendToken:(NSString *)accessToken {
	[self okDidLogin];
}

/*
 * Method will be called if [_api refreshToken] called and new access_token wasn't got
 * Метод будет вызван в случае, если вызван [_api refreshToken] и новый access_token не получен
*/
-(void)okDidNotExtendToken:(NSError *)error {

}

/*
 * Method will be called after logout ([_api logout])
 * Метод будет вызван после выхода пользователя ([_api logout])
*/
-(void)okDidLogout {
	[self.sessionStatusLabel setText:@"Not logged in"];
    [self.authButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
    [self clearUserInfo];
    
}

#pragma mark - OKRequestDelegate

/*
 * Method will be called after OKRequest got correct response
 * Метод будет вызван после того, как на данный OKRequest получен корректный ответ
*/
-(void)request:(OKRequest *)request didLoad:(id)result {
    @autoreleasepool {
        NSDictionary *resDict;
        NSArray *resArr;
        // result is either array or dictionary
        // result - это либо массив, либо словарь
        @try {
            if ([result isKindOfClass:[NSArray class]]) {
                resArr = (NSArray*)result;
                NSLog(@"array");
            }
            if ([result isKindOfClass:[NSDictionary class]]) {
                resDict = (NSDictionary*)result;
                NSLog(@"dict");
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Bad result");
        }
        // checking method and resut type and choosing action
        // проверка вызванного метода и типа результата и выбор соответствующего действия
        if ([request.url rangeOfString:@"getCurrentUser"].location != NSNotFound && resDict) {
            self.surnameTextField.text = [resDict objectForKey:@"last_name"];
            self.nameTextField.text = [resDict objectForKey:@"first_name"];
            self.countryTextField.text = [[resDict objectForKey:@"location"] valueForKey:@"country"];
            // you haven't to do actions that can take a lot of time in UI thread
            // действия, которые могут занять много времени, не должны производиться в интерфейсном потоке
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSURL *url = [NSURL URLWithString:[resDict objectForKey:@"pic_1"]];
                NSData *data = [NSData dataWithContentsOfURL:url];
                UIImage *img = [[UIImage alloc] initWithData:data];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    self.photo.image = img;
                });
            });
        }
        if ([request.url rangeOfString:@"/friends/get"].location != NSNotFound && resArr) {
            int maxStepNumber = [friends count] / 100;
            for (int currentStep = 0; currentStep <= maxStepNumber; currentStep++) {
                NSRange range;
                range.location = currentStep*100;
                range.length = (currentStep == maxStepNumber) ? ([resArr count] % 100) : 100;
                OKRequest *request = [Odnoklassniki requestWithMethodName:@"users.getInfo"
                                                                andParams:[NSMutableDictionary dictionaryWithDictionary:@{@"uids":[[resArr subarrayWithRange:range]componentsJoinedByString:@","],@"fields": @"first_name,last_name,uid,online,pic_1"}]
                                                            andHttpMethod:@"GET"
                                                              andDelegate:self];
                [request load];
            }
        }
        if ([request.url rangeOfString:@"/users/getInfo"].location != NSNotFound) {
            friends = [[NSMutableArray alloc]init];

            for (NSString *uid in resArr) {
                ALFriend *friend = [[ALFriend alloc]initWithUid:[((NSDictionary*)uid) objectForKey:@"uid"]];
                friend.name = [((NSDictionary*)uid) objectForKey:@"first_name"];
                friend.surname = [((NSDictionary*)uid) objectForKey:@"last_name"];
                friend.pic_1Url = [((NSDictionary*)uid) objectForKey:@"pic_1"];
                if ([((NSDictionary*)uid) objectForKey:@"online"]) {
                    friend.isOnline = true;
                }
                [friends addObject:friend];
            }
            [_tableView reloadData];
        }

    }
}

/*
 * Method will be called after OKRequest got incorrect response or response was't got
 * Метод будет вызван после того, как на данный OKRequest получен некорректный ответ или ответ не был получен
*/
-(void)request:(OKRequest *)request didFailWithError:(NSError *)error {
	NSLog(@"Request failed with error = %@", error);
}

#pragma mark - table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @autoreleasepool {
        static NSString *simpleTableIdentifier = @"SimpleTableItem";
        
    
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
        }
    
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", ((ALFriend*)[friends objectAtIndex:indexPath.row]).name, ((ALFriend*)[friends objectAtIndex:indexPath.row]).surname];
        if (((ALFriend*)[friends objectAtIndex:indexPath.row]).isOnline) {
            cell.detailTextLabel.text = @"online";
        }
        
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *url = [NSURL URLWithString:((ALFriend*)[friends objectAtIndex:indexPath.row]).pic_1Url];
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *img = [[UIImage alloc] initWithData:data];
            dispatch_sync(dispatch_get_main_queue(), ^{
                cell.imageView.image = img;
                [cell setNeedsLayout];
            });
        });
    return cell;
    }
}


#pragma mark - interface

-  (void)loginButtonClick:(id)sender {
    @autoreleasepool {
        if(!self->_api.isSessionValid) {
            [self->_api authorize:[NSArray arrayWithObjects:@"VALUABLE ACCESS", nil]];
        } else {
            [self->_api logout];
        }
    }
}

- (void)clearUserInfo {
    @autoreleasepool {
        [self.nameTextField setText:@""];
        [self.surnameTextField setText:@""];
        [self.countryTextField setText:@""];
        UIImage * unknownUserPicture = [UIImage imageNamed: @"q.png"];
        self.photo.image = unknownUserPicture;
        friends = nil;
        [_tableView reloadData];
    }
}

@end
