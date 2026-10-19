//
//  DYXUtil.h
//  工具层：方法交换 / 视图遍历 / 顶部控制器 / 轻提示
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface DYXUtil : NSObject

// 交换两个实例方法（幂等，重复调用只生效一次）
+ (BOOL)swizzleInstance:(SEL)orig ofClass:(Class)cls with:(SEL)replacement;
+ (BOOL)swizzleClass:(SEL)orig ofClass:(Class)cls with:(SEL)replacement;

// 仅在类存在且真的实现了 orig 时交换，返回是否成功
+ (BOOL)safeSwizzle:(Class)cls orig:(SEL)orig replacement:(SEL)replacement;

// 取当前最顶部的控制器
+ (UIViewController *)topViewController;
+ (UIWindow *)keyWindow;

// 从 from 开始沿 responder 链往上找控制器
+ (UIViewController *)viewControllerOf:(UIView *)view;

// 递归遍历视图
+ (void)walkView:(UIView *)view depth:(NSInteger)depth block:(void (^)(UIView *v, NSInteger depth))block;

// 取 view 上所有可见文字（UILabel.text / UIButton title / 自身 accessibilityLabel）
+ (NSArray<NSString *> *)textsInView:(UIView *)view;

// 轻提示（不阻塞）
+ (void)toast:(NSString *)text;

// 柔和的文本比较：忽略空白与全半角差异
+ (BOOL)text:(NSString *)a matches:(NSString *)b;

@end
