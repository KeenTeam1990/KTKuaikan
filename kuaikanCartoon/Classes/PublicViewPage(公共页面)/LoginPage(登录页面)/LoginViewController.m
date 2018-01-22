//
//  LoginViewController.m
//  kuaikanCartoon
//
//  Created by dengchen on 16/5/23.
//  Copyright © 2016年 name. All rights reserved.
//

#import "LoginViewController.h"
#import "UIView+Extension.h"
#import "ProgressHUD.h"
#import "NetWorkManager.h"
#import "UserInfoManager.h"
#import "NSString+Extension.h"
#import "registerViewController.h"
#import "CommonMacro.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *loginIcon;

@property (weak, nonatomic) IBOutlet UIButton *loginUserIcon;

@property (weak, nonatomic) IBOutlet UIButton *loginPasswordIcon;

@property (weak, nonatomic) IBOutlet UITextField *userInputView;
@property (weak, nonatomic) IBOutlet UITextField *passwordInputView;

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIView *DividingLine;
@property (weak, nonatomic) IBOutlet UIView *inputView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputViewCenterY;


@property (nonatomic,strong) registerViewController *registerVc;

@end

static NSString * const userAuthorizeUrlString = @"http://api.kuaikanmanhua.com/v1/timeline/polling";

static NSString * const signinBaseUrlString = @"http://api.kuaikanmanhua.com/v1/phone/signin";


@implementation LoginViewController

+ (void)show {
    
    UIViewController *rootVc = [self topViewControllerWithRootViewController:[[[[UIApplication sharedApplication] delegate] window] rootViewController]];
    
    LoginViewController *loginVc = [LoginViewController new];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVc];
    
    [rootVc presentViewController:nav animated:YES completion:^{
        
    }];
}

+ (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController
{
    
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

- (instancetype)init
{
    return [super initWithNibName:@"LoginViewController" bundle:nil];
}

- (void)dealloc {
    
}

static CGFloat inputViewMaxY = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = subjectColor;
    
    self.loginBtn.backgroundColor = RGB(32, 40, 48);
    self.DividingLine.backgroundColor = colorWithWhite(0.9);
    
    [self.loginBtn cornerRadius:10];
    [self.inputView cornerRadius:10];
    
    inputViewMaxY = CGRectGetMaxY(self.inputView.frame);

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    RegisterNotify(UIKeyboardWillChangeFrameNotification, @selector(keyboardFrameChange:));
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    RemoveNofify
}

- (void)keyboardFrameChange:(NSNotification *)not {
    
    CGFloat keyboard_Y = [not.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    
    CGFloat yoffset = keyboard_Y - inputViewMaxY;
    
    self.inputViewCenterY.constant = yoffset < 0 ? yoffset - 10 : 0;
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


- (void)loginBtnEnabledIfNeed {
    
    self.loginBtn.enabled = self.userInputView.text.length > 0 &&
                            self.passwordInputView.text.length > 0;
}

//{
//    "code": 200,
//    "data": {
//        "avatar_url": "http://i.kuaikanmanhua.com/default_avatar_image.jpg-w180",
//        "grade": 0,
//        "id": 13124241,
//        "nickname": "NSDengChen",
//        "reg_type": "phone",
//        "update_remind_flag": 1
//    },
//    "message": "OK"
//}

//登录
- (IBAction)login:(id)sender {
    
    if (![self canLogin]) return;
    
    dissmissCallBack dissMiss = [ProgressHUD showProgressWithStatus:@"登录中..."
                                                             inView:self.view];
    
    weakself(self);
    
    [UserInfoManager loginWithPhone:self.userInputView.text WithPassword:self.passwordInputView.text loginSucceed:^(UserInfoManager *user) {
        
        dissMiss();
        
        [ProgressHUD showSuccessWithStatus:@"登录成功" inView:weakSelf.view];
     
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        });
        
    } loginFailed:^(id faileResult, NSError *error) {
        
        dissMiss();
        
        if (error != nil) {
            [ProgressHUD showErrorWithStatus:@"网络出了点小问题" inView:weakSelf.view];
            return ;
        }
        
//        NSDictionary *result = (NSDictionary *)faileResult;
//
//        NSString *message  = result[@"message"];
//        NSNumber *code = result[@"code"];
//        
        [ProgressHUD showErrorWithStatus:@"用户名或密码不正确" inView:weakSelf.view];
        
    }];
    
    
}


- (IBAction)autoLogin:(id)sender {
    self.userInputView.text     = @"18210337715";
    self.passwordInputView.text = @"a123124125";
    [self login:nil];
}

- (BOOL)canLogin {
    
    if (self.passwordInputView.text.length < 8) {
        [ProgressHUD showErrorWithStatus:@"密码长度至少为8位" inView:self.view];
        return NO;
    }
    
    if (!self.userInputView.text.isMobile) {
        [ProgressHUD showErrorWithStatus:@"你输入的手机号无效,请重新输入" inView:self.view];
        return NO;
    }
    
    return YES;
}



//注册
- (IBAction)registered:(id)sender {
    
    [self.navigationController pushViewController:self.registerVc animated:YES];
    
}

//忘记密码
- (IBAction)forgetPassword:(UITextField *)sender {
}

//用户名开始编辑
- (IBAction)userEditBegin:(UITextField *)sender {
    self.loginIcon.highlighted = NO;
    self.loginUserIcon.highlighted = YES;
    
    
}

//用户编辑发生改动
- (IBAction)userEditChange:(UITextField *)sender {
    [self loginBtnEnabledIfNeed];
    
}
- (IBAction)userEditEnd:(UITextField *)sender {
    self.loginUserIcon.highlighted = NO;
    
    
}

//用户名开始编辑
- (IBAction)passwordEditBegin:(UITextField *)sender {
    self.loginIcon.highlighted = YES;
    self.loginPasswordIcon.highlighted = YES;
}

//用户编辑发生改动

- (IBAction)passwordEditChange:(UITextField *)sender {
    [self loginBtnEnabledIfNeed];
    
}
- (IBAction)passwordEditEnd:(UITextField *)sender {
    self.loginPasswordIcon.highlighted = NO;
    
}

//回家
- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (registerViewController *)registerVc {
    if (!_registerVc) {
        _registerVc = [registerViewController new];
    }
    return _registerVc;
}

@end
