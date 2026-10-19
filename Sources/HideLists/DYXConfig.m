//
//  DYXConfig.m
//

#import "DYXConfig.h"

NSString *const kDYXKeyHideLikes     = @"隐藏所有喜欢列表";
NSString *const kDYXKeyHideFavorites = @"隐藏所有收藏列表";
NSString *const kDYXKeyLikesPwd      = @"喜欢列表密码";
NSString *const kDYXKeyFavoritesPwd  = @"收藏列表密码";

// 解锁状态只在内存里，进程重启就没了 —— 原版也是这么做的
static BOOL gLikesUnlocked     = NO;
static BOOL gFavoritesUnlocked = NO;

@implementation DYXConfig

+ (instancetype)shared {
    static DYXConfig *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[DYXConfig alloc] init]; });
    return s;
}

- (NSUserDefaults *)defaults {
    return [NSUserDefaults standardUserDefaults];
}

- (BOOL)boolForKey:(NSString *)key {
    id v = [[self defaults] objectForKey:key];
    if (!v) return NO;
    if ([v respondsToSelector:@selector(boolValue)]) return [v boolValue];
    if ([v isKindOfClass:[NSString class]]) return [(NSString *)v boolValue];
    return NO;
}

- (void)setBool:(BOOL)on forKey:(NSString *)key {
    [[self defaults] setObject:[NSNumber numberWithBool:on] forKey:key];
    [[self defaults] synchronize];
}

- (BOOL)hideLikes     { return [self boolForKey:kDYXKeyHideLikes]; }
- (BOOL)hideFavorites { return [self boolForKey:kDYXKeyHideFavorites]; }

- (void)setHideLikes:(BOOL)on     { [self setBool:on forKey:kDYXKeyHideLikes]; }
- (void)setHideFavorites:(BOOL)on { [self setBool:on forKey:kDYXKeyHideFavorites]; }

- (NSString *)stringForKey:(NSString *)key {
    id v = [[self defaults] objectForKey:key];
    if ([v isKindOfClass:[NSString class]]) return v;
    if (v) return [v description];
    return @"";
}

- (NSString *)likesPassword     { return [self stringForKey:kDYXKeyLikesPwd]; }
- (NSString *)favoritesPassword { return [self stringForKey:kDYXKeyFavoritesPwd]; }

- (void)setPassword:(NSString *)pwd forKind:(DYXListKind)kind {
    if (!pwd) pwd = @"";
    NSString *key = (kind == DYXListKindLikes) ? kDYXKeyLikesPwd : kDYXKeyFavoritesPwd;
    [[self defaults] setObject:pwd forKey:key];
    [[self defaults] synchronize];
}

- (BOOL)isLikesPageHiddenBySwitch {
    return [self hideLikes];
}

- (BOOL)shouldHideKind:(DYXListKind)kind {
    if (kind == DYXListKindLikes)     return [self hideLikes];
    if (kind == DYXListKindFavorites) return [self hideFavorites];
    return NO;
}

- (NSString *)passwordForKind:(DYXListKind)kind {
    if (kind == DYXListKindLikes)     return [self likesPassword];
    if (kind == DYXListKindFavorites) return [self favoritesPassword];
    return @"";
}

- (BOOL)isUnlocked:(DYXListKind)kind {
    if (kind == DYXListKindLikes)     return gLikesUnlocked;
    if (kind == DYXListKindFavorites) return gFavoritesUnlocked;
    return NO;
}

- (void)setUnlocked:(BOOL)unlocked forKind:(DYXListKind)kind {
    if (kind == DYXListKindLikes)     gLikesUnlocked = unlocked;
    if (kind == DYXListKindFavorites) gFavoritesUnlocked = unlocked;
}

@end
