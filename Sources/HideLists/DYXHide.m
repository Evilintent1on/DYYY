//
//  DYXHide.m
//

#import "DYXHide.h"
#import "DYXUtil.h"
#import <objc/runtime.h>

static const NSInteger kDYXOverlayTag = 0x0D7C001;

@interface DYXPageState : NSObject
@property (nonatomic, assign) DYXListKind kind;
@property (nonatomic, strong) NSMutableArray<UIView *> *concealedViews;
@end

@implementation DYXPageState
- (instancetype)init {
    if ((self = [super init])) {
        _kind = DYXListKindNone;
        _concealedViews = [NSMutableArray array];
    }
    return self;
}
@end

@implementation DYXHide

#pragma mark - 页面识别

+ (NSString *)effectiveTitle:(UIViewController *)vc {
    if (!vc) return nil;
    if (vc.title.length) return vc.title;
    if (vc.navigationItem.title.length) return vc.navigationItem.title;
    if (vc.tabBarItem.title.length) return vc.tabBarItem.title;
    return nil;
}

+ (DYXListKind)kindOfController:(UIViewController *)vc {
    if (!vc) return DYXListKindNone;

    // 1) 先看标题 —— 最稳
    NSString *title = [self effectiveTitle:vc];
    if (title.length) {
        if ([DYXUtil text:title matches:@"喜欢"]) return DYXListKindLikes;
        if ([DYXUtil text:title matches:@"收藏"]) return DYXListKindFavorites;
    }

    // 2) 再看类名 —— 抖音不同版本类名会变，所以给一批关键词
    NSString *cls = NSStringFromClass([vc class]);
    if (cls.length) {
        NSString *lower = [cls lowercaseString];
        if ([lower containsString:@"likes"]) return DYXListKindLikes;
        if ([lower containsString:@"favorite"] || [lower containsString:@"collect"]) {
            return DYXListKindFavorites;
        }
    }
    return DYXListKindNone;
}

#pragma mark - 状态存取

+ (DYXPageState *)stateOf:(UIViewController *)vc create:(BOOL)create {
    DYXPageState *s = objc_getAssociatedObject(vc, "dyx_state");
    if (!s && create) {
        s = [[DYXPageState alloc] init];
        objc_setAssociatedObject(vc, "dyx_state", s, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return s;
}

#pragma mark - 找出「内容区」

+ (UIView *)contentViewOf:(UIViewController *)vc {
    __block UIView *best = nil;
    __block CGFloat bestArea = 0;
    __block UIView *tabBarLike = nil;

    [DYXUtil walkView:vc.view depth:0 block:^(UIView *v, NSInteger depth) {
        if (![v isKindOfClass:[UIScrollView class]]) return;
        if (v.hidden || v.alpha < 0.05) return;
        CGSize s = v.bounds.size;
        CGFloat area = s.width * s.height;
        if (area > bestArea) {
            bestArea = area;
            best = v;
        }
    }];
    (void)tabBarLike;
    return best;
}

#pragma mark - 遮 / 放

+ (void)conceal:(UIViewController *)vc state:(DYXPageState *)state {
    UIView *content = [self contentViewOf:vc];
    if (content && !content.hidden) {
        content.hidden = YES;
        [state.concealedViews addObject:content];
    }

    if ([vc.view viewWithTag:kDYXOverlayTag]) return;

    UILabel *tip = [[UILabel alloc] initWithFrame:vc.view.bounds];
    tip.tag = kDYXOverlayTag;
    tip.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tip.textAlignment = NSTextAlignmentCenter;
    tip.numberOfLines = 0;
    tip.backgroundColor = vc.view.backgroundColor ?: [UIColor blackColor];
    tip.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    tip.font = [UIFont systemFontOfSize:14];

    NSString *pwd = [[DYXConfig shared] passwordForKind:state.kind];
    if (pwd.length) {
        tip.text = @"内容已隐藏\n摇一摇输入密码查看";
    } else {
        tip.text = @"内容已隐藏";
    }
    [vc.view addSubview:tip];
    [vc.view bringSubviewToFront:tip];
}

+ (void)reveal:(UIViewController *)vc state:(DYXPageState *)state {
    UIView *overlay = [vc.view viewWithTag:kDYXOverlayTag];
    if (overlay) [overlay removeFromSuperview];

    for (UIView *v in state.concealedViews) {
        v.hidden = NO;
    }
    [state.concealedViews removeAllObjects];
}

#pragma mark - 对外入口

+ (void)applyToController:(UIViewController *)vc {
    if (!vc) return;

    DYXListKind kind = [self kindOfController:vc];
    if (kind == DYXListKindNone) {
        [self refreshProfileTabs:vc];
        return;
    }

    DYXPageState *state = [self stateOf:vc create:YES];
    state.kind = kind;

    DYXConfig *cfg = [DYXConfig shared];
    BOOL shouldHide = [cfg shouldHideKind:kind];
    if (!shouldHide) {
        [self reveal:vc state:state];
        return;
    }

    // 有密码 & 本次已解锁 —— 放行
    NSString *pwd = [cfg passwordForKind:kind];
    if (pwd.length && [cfg isUnlocked:kind]) {
        [self reveal:vc state:state];
        return;
    }

    [self conceal:vc state:state];
}

+ (void)resetController:(UIViewController *)vc {
    if (!vc) return;
    DYXPageState *state = [self stateOf:vc create:NO];
    if (!state) return;
    [self reveal:vc state:state];
    // 离开页面就重新上锁，回来还得摇一摇
    if (state.kind != DYXListKindNone) {
        [[DYXConfig shared] setUnlocked:NO forKind:state.kind];
    }
    state.kind = DYXListKindNone;
}

#pragma mark - 「我的」页顶部 tab 隐藏

+ (void)refreshProfileTabs:(UIViewController *)vc {
    DYXConfig *cfg = [DYXConfig shared];
    BOOL hideLikes = [cfg hideLikes];
    BOOL hideFav   = [cfg hideFavorites];
    if (!hideLikes && !hideFav) return;

    // 只在「我的」这类页面动手，避免把别的页面的文字也藏了
    NSString *cls = [NSStringFromClass([vc class]) lowercaseString];
    BOOL looksLikeProfile = ([cls containsString:@"profile"] ||
                            [cls containsString:@"user"] ||
                            [cls containsString:@"mine"]);
    if (!looksLikeProfile) return;

    [DYXUtil walkView:vc.view depth:0 block:^(UIView *v, NSInteger depth) {
        if (depth > 20) return;
        NSString *text = nil;
        if ([v isKindOfClass:[UILabel class]]) text = [(UILabel *)v text];
        if ([v isKindOfClass:[UIButton class]]) text = [(UIButton *)v titleForState:UIControlStateNormal];
        if (!text.length) return;

        BOOL isLikes = [DYXUtil text:text matches:@"喜欢"];
        BOOL isFav   = [DYXUtil text:text matches:@"收藏"];
        if (!isLikes && !isFav) return;
        if (isLikes && !hideLikes) return;
        if (isFav && !hideFav) return;

        // 往上找两三层，把整个 tab 单元一起藏掉，免得只剩个空位
        UIView *target = v;
        for (NSInteger i = 0; i < 3; i++) {
            UIView *p = target.superview;
            if (!p || [p isKindOfClass:[UIScrollView class]]) break;
            if (p.bounds.size.height > 120.0) break;
            target = p;
        }
        target.hidden = YES;
    }];
}

@end
