//
//  DYXUtil.m
//

#import "DYXUtil.h"

@implementation DYXUtil

#pragma mark - 方法交换

+ (BOOL)swizzleInstance:(SEL)orig ofClass:(Class)cls with:(SEL)replacement {
    if (!cls || !orig || !replacement) return NO;

    Method m1 = class_getInstanceMethod(cls, orig);
    Method m2 = class_getInstanceMethod(cls, replacement);
    if (!m1 || !m2) return NO;

    // 先用添加的方式把 replacement 挂到本类上，避免重复交换
    BOOL added = class_addMethod(cls, orig,
                                 method_getImplementation(m2),
                                 method_getTypeEncoding(m2));
    if (added) {
        class_replaceMethod(cls, replacement,
                            method_getImplementation(m1),
                            method_getTypeEncoding(m1));
    } else {
        method_exchangeImplementations(m1, m2);
    }
    return YES;
}

+ (BOOL)swizzleClass:(SEL)orig ofClass:(Class)cls with:(SEL)replacement {
    if (!cls) return NO;
    Class meta = object_getClass(cls);
    return [self swizzleInstance:orig ofClass:meta with:replacement];
}

+ (BOOL)safeSwizzle:(Class)cls orig:(SEL)orig replacement:(SEL)replacement {
    if (!cls) return NO;
    if (!class_getInstanceMethod(cls, orig)) return NO;
    if (!class_getInstanceMethod(cls, replacement)) return NO;
    return [self swizzleInstance:orig ofClass:cls with:replacement];
}

#pragma mark - 窗口 / 控制器

+ (UIWindow *)keyWindow {
    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(delegate)]) {
        id delegate = app.delegate;
        if (delegate && [delegate respondsToSelector:@selector(window)]) {
            UIWindow *w = [delegate window];
            if (w) return w;
        }
    }
    NSArray *windows = [app windows];
    for (NSInteger i = (NSInteger)windows.count - 1; i >= 0; i--) {
        UIWindow *w = [windows objectAtIndex:(NSUInteger)i];
        if (w.isKeyWindow) return w;
    }
    return windows.count ? [windows firstObject] : nil;
}

+ (UIViewController *)topViewController {
    UIViewController *vc = [[self keyWindow] rootViewController];
    while (vc) {
        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = [(UINavigationController *)vc topViewController];
        } else if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = [(UITabBarController *)vc selectedViewController];
        } else if (vc.presentedViewController) {
            vc = vc.presentedViewController;
        } else {
            break;
        }
    }
    return vc;
}

+ (UIViewController *)viewControllerOf:(UIView *)view {
    UIResponder *r = view;
    while (r) {
        if ([r isKindOfClass:[UIViewController class]]) return (UIViewController *)r;
        r = [r nextResponder];
    }
    return nil;
}

#pragma mark - 视图遍历

+ (void)walkView:(UIView *)view depth:(NSInteger)depth block:(void (^)(UIView *, NSInteger))block {
    if (!view || depth > 24) return;
    block(view, depth);
    for (UIView *sub in view.subviews) {
        [self walkView:sub depth:depth + 1 block:block];
    }
}

+ (NSArray<NSString *> *)textsInView:(UIView *)view {
    NSMutableArray *out = [NSMutableArray array];
    [self walkView:view depth:0 block:^(UIView *v, NSInteger d) {
        if ([v isKindOfClass:[UILabel class]]) {
            NSString *t = [(UILabel *)v text];
            if (t.length) [out addObject:t];
        }
        if ([v isKindOfClass:[UIButton class]]) {
            NSString *t = [(UIButton *)v titleForState:UIControlStateNormal];
            if (t.length) [out addObject:t];
        }
        NSString *al = v.accessibilityLabel;
        if (al.length) [out addObject:al];
    }];
    return out;
}

+ (BOOL)text:(NSString *)a matches:(NSString *)b {
    if (!a || !b) return NO;
    NSString *x = [a stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *y = [b stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([x isEqualToString:y]) return YES;
    // 有些版本会带后缀，比如「喜欢 12」
    if (x.length && y.length && ([x hasPrefix:y] || [y hasPrefix:x])) {
        return MIN(x.length, y.length) >= 2;
    }
    return NO;
}

#pragma mark - 轻提示

+ (void)toast:(NSString *)text {
    if (!text.length) return;
    UIWindow *win = [self keyWindow];
    if (!win) return;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14];
    label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.78];
    label.layer.cornerRadius = 10.0;
    label.layer.masksToBounds = YES;
    label.alpha = 0.0;

    CGFloat maxW = win.bounds.size.width - 80.0;
    CGSize fit = [label sizeThatFits:CGSizeMake(maxW, 200.0)];
    CGFloat w = fit.width + 32.0;
    CGFloat h = fit.height + 20.0;
    label.frame = CGRectMake((win.bounds.size.width - w) / 2.0,
                             win.bounds.size.height - 160.0,
                             w, h);
    [win addSubview:label];

    [UIView animateWithDuration:0.18 animations:^{
        label.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 delay:1.4 options:0 animations:^{
            label.alpha = 0.0;
        } completion:^(BOOL done) {
            [label removeFromSuperview];
        }];
    }];
}

@end
