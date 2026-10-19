//
//  DYXConfig.h
//  DYHideLists —— 抖音「我的」页 喜欢列表 / 收藏列表 隐藏
//
//  配置层：全部落 NSUserDefaults，键名沿用原版（原版的键就是界面上的中文标题，
//  这样从原版切过来，之前的开关状态能直接读到）。
//

#import <Foundation/Foundation.h>

// —— 键名（与原版一致，勿改，改了就读不到旧配置）——
extern NSString *const kDYXKeyHideLikes;       // 隐藏所有喜欢列表
extern NSString *const kDYXKeyHideFavorites;   // 隐藏所有收藏列表
extern NSString *const kDYXKeyLikesPwd;        // 喜欢列表密码
extern NSString *const kDYXKeyFavoritesPwd;    // 收藏列表密码

typedef NS_ENUM(NSInteger, DYXListKind) {
    DYXListKindNone = 0,
    DYXListKindLikes,      // 喜欢列表
    DYXListKindFavorites,  // 收藏列表
};

@interface DYXConfig : NSObject

+ (instancetype)shared;

// 总开关
- (BOOL)hideLikes;
- (BOOL)hideFavorites;

// 密码（空串 = 未设置密码，此时按「直接隐藏、不可解锁」处理）
- (NSString *)likesPassword;
- (NSString *)favoritesPassword;

// 便捷判断
- (BOOL)shouldHideKind:(DYXListKind)kind;
- (NSString *)passwordForKind:(DYXListKind)kind;

// 本次运行期的临时解锁状态（离开页面 / 超时后自动失效）
- (BOOL)isUnlocked:(DYXListKind)kind;
- (void)setUnlocked:(BOOL)unlocked forKind:(DYXListKind)kind;

// 供设置页写入
- (void)setHideLikes:(BOOL)on;
- (void)setHideFavorites:(BOOL)on;
- (void)setPassword:(NSString *)pwd forKind:(DYXListKind)kind;

@end
