#import <UIKit/UIKit.h>
#import <substrate.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#import <Foundation/Foundation.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <substrate.h>
#import <objc/runtime.h>

@interface MyFloatingBall : UIView
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture; // Added long press gesture recognizer
@property (nonatomic, strong) UIAlertController *alertController;
@end

@implementation MyFloatingBall

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Set the appearance of the floating ball
        self.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:0.8];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 2.0;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        
        // Add tap gesture recognizer
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:self.tapGesture];
        
        // Add pan gesture recognizer
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGesture];
        
        // Add long press gesture recognizer
        self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        self.longPressGesture.minimumPressDuration = 2.0; // Set minimum press duration to 3 seconds
        [self addGestureRecognizer:self.longPressGesture];
    }

    NSLog(@"[IOSRE] - MyFloatingBall initWithFrame");

    return self;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    NSLog(@"[IOSRE] - MyFloatingBall handleTap");
    [self showInputDialog];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"[IOSRE] - MyFloatingBall handleLongPress");
        [self showCloseConfirmation];
    }
}

- (void)showCloseConfirmation {
    self.alertController = [UIAlertController alertControllerWithTitle:@"关闭悬浮框"
                                                               message:@"是否关闭悬浮框？"
                                                        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self removeFromSuperview];
                                                         }];
    [self.alertController addAction:confirmAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self.alertController dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [self.alertController addAction:cancelAction];

    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }

    [topViewController presentViewController:self.alertController animated:YES completion:nil];
}

- (void)showInputDialog {
    // 版本号
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    // 获取 /private/var/mobile/Containers/Data/Application/82119542-140C-4F42-97B7-BA90D9E06671/Library/Preferences/com.hpbr.bosszhipin.plist 文件中的内容

    // 拼接得到正确的路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Preferences/com.hpbr.bosszhipin.plist"];
    NSLog(@"[IOSRE] - MyFloatingBall showInputDialog path: %@", path);
    
    // 读取文件
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    NSLog(@"[IOSRE] - MyFloatingBall showInputDialog dict: %@", dict);

    // 获取文件中的内容
    // 获取手机号 - [cur_login_phone_number]
    NSString *phone = @"获取手机号失败";
    if (dict[@"cur_login_phone_number"]) {
        phone = dict[@"cur_login_phone_number"];
    }

    // 提取手机号部分
    NSRange range = [phone rangeOfString:@" "];
    if (range.location != NSNotFound) {
        phone = [phone substringToIndex:range.location];
    }

    // 获取Token - [iPhone10,1-kConfigUserIdentify 字典下的 t2]
    NSString *token = @"获取coockie失败";
    if (dict[@"iPhone10,1-kConfigUserIdentify"][@"t2"]) {
        token = dict[@"iPhone10,1-kConfigUserIdentify"][@"t2"];
    }
    
    // 获取用户吗 - [kConfigUserAllInfo开头的 字典下的 userDetail 字典下的 userInfo 字典下的 name]
    // 第一个值可能是 kConfigUserAllInfo-1-632039906，因此需要通过匹配 kConfigUserAllInfo- 开头的 key 来获取对应的 value
    NSString *userName = @"获取姓名失败";
    NSLog(@"[IOSRE] - MyFloatingBall showInputDialog dict: %@", dict);
    for (NSString *key in dict.allKeys) {
        if ([key hasPrefix:@"kConfigUserAllInfo-"]) {
            NSLog(@"[IOSRE] - MyFloatingBall showInputDialog key: %@", key);
            NSDictionary *userDetial = dict[key][@"userDetail"];
            if (userDetial[@"userInfo"][@"name"]) {
                userName = userDetial[@"userInfo"][@"name"];
            }
        }
    }

    // 展示弹窗，显示上面获取到的信息
    self.alertController = [UIAlertController alertControllerWithTitle:@"设备信息"
                                                               message:nil
                                                        preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *copyVersionAction = [UIAlertAction actionWithTitle:currentVersion
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                                 pasteboard.string = currentVersion;
                                                             }];
    [self.alertController addAction:copyVersionAction];
    
    UIAlertAction *copyPhoneAction = [UIAlertAction actionWithTitle:phone
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                               pasteboard.string = phone;
                                                           }];
    [self.alertController addAction:copyPhoneAction];

    UIAlertAction *copyTokenAction = [UIAlertAction actionWithTitle:token
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                               pasteboard.string = token;
                                                           }];
    [self.alertController addAction:copyTokenAction];

    UIAlertAction *copyUserNameAction = [UIAlertAction actionWithTitle:userName
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                               pasteboard.string = userName;
                                                           }];
    [self.alertController addAction:copyUserNameAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"关闭"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

    [self.alertController addAction:cancelAction];

    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }

    [topViewController presentViewController:self.alertController animated:YES completion:nil];
}

@end

%hook WebViewController

- (void)logoutEvent
{
    return;
}

%end

%hook CustomWKWebView

- (_Bool)judgeHostIsValid
{
    return 1;
}

- (_Bool)canWebViewGoBack
{
    return 1;
}

%end

%hook BZGuideUpdateVersionView

- (void)showNewVersionUpdateView:(id)arg1 andNeedForceUpdate:(_Bool)arg2 withUpdateUrl:(id)arg3 andIsFromTestFlight:(_Bool)arg4
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView showNewVersionUpdateView skiped");
    return;
}

- (void)viewDidLoad
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView viewDidLoad skiped");
    return;
}

- (long long)overrideUserInterfaceStyle
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView overrideUserInterfaceStyle skiped");
    return 1;
}
- (long long)readCurrStatusBarStyle
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView readCurrStatusBarStyle skiped");
    return 1;
}
- (long long)revealStatausBarStyle
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView revealStatausBarStyle skiped");
    return 1;
}
- (long long)preferredStatusBarStyle
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView preferredStatusBarStyle skiped");
    return 1;
}

- (void)updateStatusBarStyle
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView updateStatusBarStyle skiped");
    return;
}
- (void)updateShowViewLevel
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView updateShowViewLevel skiped");
    return;
}
- (void)updateWindowShowStatus
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView updateWindowShowStatus skiped");
    return;
}

%end

%hook BZGuideUpdateVersionView

- (void)onInit
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView onInit skiped");
    return;
}

- (void)showUpdateContent:(id)arg1 andNeedForceUpdate:(_Bool)arg2 withUpdateUrl:(id)arg3 andIsFromTestFlight:(_Bool)arg4
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView showUpdateContent skiped");
    return;
}

- (void)updateContentFrame
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView updateContentFrame skiped");
    return;
}

- (void)updateFrameWithScreenDidRotate:(id)arg1
{
    %log;
    NSLog(@"[IOSRE] - BZGuideUpdateVersionView updateFrameWithScreenDidRotate skiped");
    return;
}

%end

%hook BZGuideWindow

+ (void)showNewVersionUpdateView:(id)arg1 andNeedForceUpdate:(_Bool)arg2 withUpdateUrl:(id)arg3 andIsFromTestFlight:(_Bool)arg4
{
    %log;
    NSLog(@"[IOSRE] - BZGuideWindow showNewVersionUpdateView skiped");
    return;
}

%end

@interface KZAlert : UIAlertController
@end

@implementation KZAlert

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"[IOSRE] UIAlertController viewDidAppear");
    [self addAction:[UIAlertAction actionWithTitle:@"Other Action" style:UIAlertActionStyleDefault handler:nil]];
}

@end

%hook KZAlert

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"[IOSRE] UIAlertController viewDidAppear");
    [self addAction:[UIAlertAction actionWithTitle:@"Other Action" style:UIAlertActionStyleDefault handler:nil]];
}

%end

%hook AppDelegate

- (BOOL)application:(id)application didFinishLaunchingWithOptions:(id)launchOptions {
    %orig;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat floatingBallWidth = 50;
    CGFloat floatingBallHeight = 50;
    CGFloat floatingBallX = screenWidth - floatingBallWidth;
    CGFloat floatingBallY = screenHeight / 4 - floatingBallHeight / 2;
    MyFloatingBall *floatingBall = [[MyFloatingBall alloc] initWithFrame:CGRectMake(floatingBallX, floatingBallY, floatingBallWidth, floatingBallHeight)];
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:floatingBall];
    [keyWindow bringSubviewToFront:floatingBall];
    NSLog(@"[IOSRE] - AppDelegate application:didFinishLaunchingWithOptions");
    return YES;
}

%end

