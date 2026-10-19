//
//  DYXPwdGate.m
//

#import "DYXPwdGate.h"
#import "DYXHide.h"
#import "DYXUtil.h"

@implementation DYXPwdGate

+ (NSString *)shownTextForKind:(DYXListKind)kind {
    return (kind == DYXListKindLikes) ? @"已显示喜欢内容" : @"已显示收藏内容";
}

+ (NSString *)hiddenTextForKind:(DYXListKind)kind {
    return (kind == DYXListKindLikes) ? @"已隐藏喜欢内容" : @"已隐藏收藏内容";
}

+ (void)handleShake {
    UIViewController *top = [DYXUtil topViewController];
    if (!top) return;

    DYXListKind kind = [DYXHide kindOfController:top];
    if (kind == DYXListKindNone) return;

    DYXConfig *cfg = [DYXConfig shared];
    if (![cfg shouldHideKind:kind]) return;

    NSString *pwd = [cfg passwordForKind:kind];
    if (!pwd.length) {
        [DYXUtil toast:@"还没设置密码"];
        return;
    }

    if ([cfg isUnlocked:kind]) {
        // 已解锁再摇一次 —— 重新上锁
        [cfg setUnlocked:NO forKind:kind];
        [DYXHide applyToController:top];
        [DYXUtil toast:[self hiddenTextForKind:kind]];
        return;
    }

    [self promptPasswordForKind:kind controller:top];
}

+ (void)promptPasswordForKind:(DYXListKind)kind controller:(UIViewController *)vc {
    NSString *pwd = [[DYXConfig shared] passwordForKind:kind];
    if (!pwd.length) {
        [DYXUtil toast:@"还没设置密码"];
        return;
    }

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"输入密码"
                                           message:(kind == DYXListKindLikes ? @"喜欢列表已上锁" : @"收藏列表已上锁")
                                    preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"密码";
        tf.secureTextEntry = YES;
        tf.keyboardType = UIKeyboardTypeNumberPad;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *input = alert.textFields.firstObject.text ?: @"";
        if ([input isEqualToString:pwd]) {
            [[DYXConfig shared] setUnlocked:YES forKind:kind];
            UIViewController *target = vc ?: [DYXUtil topViewController];
            [DYXHide applyToController:target];
            [DYXUtil toast:[self shownTextForKind:kind]];
        } else {
            [DYXUtil toast:@"密码不对"];
        }
    }]];

    UIViewController *presenter = vc ?: [DYXUtil topViewController];
    [presenter presentViewController:alert animated:YES completion:nil];
}

@end
