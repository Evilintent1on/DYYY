//
//  DYXHook.m
//  接入层：把上面几层挂到系统类上
//
//  说明：这里不用 Logos（%hook），全部走 method swizzling，
//  好处是不依赖 theos 的预处理宏，任何 theos 版本都能编。
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "DYXConfig.h"
#import "DYXUtil.h"
#import "DYXHide.h"
#import "DYXPwdGate.h"

#pragma mark - UIViewController：进页面 / 离开页面

@interface UIViewController (DYXHooks)
@end

@implementation UIViewController (DYXHooks)

- (void)dyx_viewDidAppear:(BOOL)animated {
    // 交换之后，这个调用其实进的是系统的 viewDidAppear:
    [self dyx_viewDidAppear:animated];

    [DYXHide applyToController:self];

    // 列表内容是异步回来的，进场后再补两刀
    __weak UIViewController *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong UIViewController *strongSelf = weakSelf;
        if (strongSelf) [DYXHide applyToController:strongSelf];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong UIViewController *strongSelf = weakSelf;
        if (strongSelf) [DYXHide applyToController:strongSelf];
    });
}

- (void)dyx_viewWillAppear:(BOOL)animated {
    [self dyx_viewWillAppear:animated];
    [DYXHide applyToController:self];
}

- (void)dyx_viewWillDisappear:(BOOL)animated {
    [DYXHide resetController:self];
    [self dyx_viewWillDisappear:animated];
}

@end

#pragma mark - UIWindow：摇一摇 + 设置入口

@interface UIWindow (DYXHooks)
@end

@implementation UIWindow (DYXHooks)

- (void)dyx_motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        [DYXPwdGate handleShake];
    }
    [self dyx_motionEnded:motion withEvent:event];
}

@end

#pragma mark - 安装

__attribute__((constructor))
static void DYXInstallHooks(void) {
    @autoreleasepool {
        [DYXUtil swizzleInstance:@selector(viewDidAppear:)
                         ofClass:[UIViewController class]
                            with:@selector(dyx_viewDidAppear:)];

        [DYXUtil swizzleInstance:@selector(viewWillAppear:)
                         ofClass:[UIViewController class]
                            with:@selector(dyx_viewWillAppear:)];

        [DYXUtil swizzleInstance:@selector(viewWillDisappear:)
                         ofClass:[UIViewController class]
                            with:@selector(dyx_viewWillDisappear:)];

        [DYXUtil swizzleInstance:@selector(motionEnded:withEvent:)
                         ofClass:[UIWindow class]
                            with:@selector(dyx_motionEnded:withEvent:)];
    }
}
