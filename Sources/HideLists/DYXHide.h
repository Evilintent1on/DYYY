//
//  DYXHide.h
//  核心：识别「喜欢列表 / 收藏列表」页面，并按配置遮起来
//

#import <UIKit/UIKit.h>
#import "DYXConfig.h"

@interface DYXHide : NSObject

// 判定这个控制器是不是「喜欢 / 收藏」列表页（认不出来就返回 None）
+ (DYXListKind)kindOfController:(UIViewController *)vc;

// 进入页面时调用：需要隐藏就遮住，解锁过就放出来
+ (void)applyToController:(UIViewController *)vc;

// 离开页面时调用：清掉遮罩、复位解锁状态
+ (void)resetController:(UIViewController *)vc;

// 「我的」页顶部 tab（作品 / 喜欢 / 收藏）按开关隐藏
+ (void)refreshProfileTabs:(UIViewController *)vc;

@end
