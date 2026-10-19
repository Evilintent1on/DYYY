//
//  DYXPwdGate.h
//  密码门：摇一摇 → 输入密码 → 放行
//

#import <UIKit/UIKit.h>
#import "DYXConfig.h"

@interface DYXPwdGate : NSObject

// 处理摇一摇（由 window 的 motionEnded 打进来）
+ (void)handleShake;

// 手动弹密码框
+ (void)promptPasswordForKind:(DYXListKind)kind controller:(UIViewController *)vc;

@end
