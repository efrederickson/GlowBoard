#import "SpringBoard.h"
#import <UIKit/UIBezierPath.h>
#import "Apex/STKGroupView.h"
#import "Apex/STKGroup.h"
#import "Apex/STKGroupLayout.h"
#import "UIImage+AverageColor.h"
struct STKGroupSlot { // Apex 2
    unsigned long long position;
    unsigned long long index;
};
#import <UIKit/UIScreen.h>
#import <substrate.h>
#define SYSTEM_VERSION_EQUAL_TO(_gVersion)                  ( fabsf(NSFoundationVersionNumber - _gVersion) < DBL_EPSILON )
#define SYSTEM_VERSION_GREATER_THAN(_gVersion)              ( NSFoundationVersionNumber >  _gVersion )
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(_gVersion)  ( NSFoundationVersionNumber > _gVersion || SYSTEM_VERSION_EQUAL_TO(_gVersion) )
#define SYSTEM_VERSION_LESS_THAN(_gVersion)                 ( NSFoundationVersionNumber <  _gVersion )
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(_gVersion)     ( NSFoundationVersionNumber < _gVersion || SYSTEM_VERSION_EQUAL_TO(_gVersion)  )

void updateGlowView(SBIconView *v, BOOL forceNotif, BOOL isSwitcher);

#define RILog(fmt, ...) NSLog((@"[GlowBoard] " fmt), ##__VA_ARGS__)

#define kGB_NotifAnimKey @"GB_NotifAnimKey"
#define kGB_PulseAnimKey @"GB_PulseAnimKey"

typedef enum {
    GBDotStyleDark,
    GBDotStyleLight,
    GBDotStyleDarkBlur,
    GBDotStyleLightBlur,
    GBDotStyleExtraLightBlur,
} GBDotStyle;

NSMutableSet *suppressedIcons; // Used for Apex 2 compatibility
NSMutableSet *ncIcons = [[NSMutableSet alloc] init];

NSDictionary *prefs = nil;

BOOL enabled = YES;
BOOL showInSwitcher = YES;
BOOL glowDock = YES;
BOOL animateNotifications = YES;
BOOL glowFolders = NO;
BOOL bounceDock = YES;
BOOL animateGlow = YES;
BOOL disableNotificationGlow = NO;
BOOL disableRunningGlow = NO;
BOOL requireBadge = YES;
int badgedColorMode = 2;
int activeColorMode = 0;
BOOL disableUpdateGlow = NO;
int updatedColorMode = 3;
BOOL showDot = YES;
BOOL showDotInSwitcher = YES;
CGFloat dotSize = 5;
BOOL shiftDockUp = YES;
GBDotStyle dotStyle = GBDotStyleDark;
int betaColorMode = 9;
BOOL disableBetaGlow = NO;

/* iOS 8 only so moved here for simple checking (lower iOS versions) */
BOOL iconIsBeta(SBIcon *icon)
{
    if ([icon respondsToSelector:@selector(isBeta)])
        return icon.isBeta;
    return NO;
}

UIColor* getColor(SBIconImageView *view)
{
    BOOL isUpdated = disableUpdateGlow == NO && (view.icon.application._isRecentlyUpdated || view.icon.application._isNewlyInstalled);
    int color = view.icon.application.isRunning ? activeColorMode : (isUpdated ? updatedColorMode : (iconIsBeta(view.icon) ? betaColorMode : badgedColorMode));
    UIColor *c = [UIColor whiteColor];
    if (color == 0) // WHITE
        c = [UIColor whiteColor];
    else if (color == 1) // LIGHT WHITE
        c = [UIColor colorWithWhite:1.0 alpha:0.6];
    else if (color == 2) // RED
        c = [UIColor redColor];     //[UIColor colorWithRed:184/255.0f green:36/255.0f blue:36/255.0f alpha:1.0f];
    else if (color == 3) // PURPLE
        c = [UIColor colorWithRed:204/255.0f green:0/255.0f blue:255/255.0f alpha:1.0f];
    else if (color == 4) // GREEN
        c = [UIColor colorWithRed:55/255.0f green:243/255.0f blue:126/255.0f alpha:1.0f];
    else if (color == 5) // BLUE
        c = [UIColor colorWithRed:55/255.0f green:188/255.0f blue:243/255.0f alpha:1.0f];
    else if (color == 6) // LIME
        c = [UIColor colorWithRed:188/255.0f green:243/255.0f blue:55/255.0f alpha:1.0f];
    else if (color == 7) // DARK
        c = [UIColor blackColor];
    else if (color == 8) // ADAPTIVE
        c = [view.contentsImage averageColor];
    else if (color == 9) // ORANGE
        c = [UIColor orangeColor];
            
    return c;
}

void reloadSettings(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    if (prefs)
    {
        [prefs release];
        prefs = nil;
    }
    prefs = [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.efrederickson.glowboard.settings.plist"] retain];

    if ([prefs objectForKey:@"enabled"] != nil)
        enabled = [[prefs objectForKey:@"enabled"] boolValue];
    else
        enabled = YES;

    if ([prefs objectForKey:@"showInSwitcher"] != nil)
        showInSwitcher = [[prefs objectForKey:@"showInSwitcher"] boolValue];
    else
        showInSwitcher = YES;

    if ([prefs objectForKey:@"glowDock"] != nil)
        glowDock = [[prefs objectForKey:@"glowDock"] boolValue];
    else
        glowDock = YES;

    if ([prefs objectForKey:@"animateNotifications"] != nil)
        animateNotifications = [[prefs objectForKey:@"animateNotifications"] boolValue];
    else
        animateNotifications = YES;
        
    if ([prefs objectForKey:@"glowFolders"] != nil)
        glowFolders = [[prefs objectForKey:@"glowFolders"] boolValue];
    else
        glowFolders = NO;
        
    if ([prefs objectForKey:@"bounceDock"] != nil)
        bounceDock = [[prefs objectForKey:@"bounceDock"] boolValue];
    else
        bounceDock = YES;

    if ([prefs objectForKey:@"animateGlow"] != nil)
        animateGlow = [[prefs objectForKey:@"animateGlow"] boolValue];
    else
        animateGlow = YES;

    if ([prefs objectForKey:@"activeColor"] != nil)
        activeColorMode = [[prefs objectForKey:@"activeColor"] intValue];
    else
        activeColorMode = 0;

    if ([prefs objectForKey:@"badgedColor"] != nil)
        badgedColorMode = [[prefs objectForKey:@"badgedColor"] intValue];
    else
        badgedColorMode = 2;

    if ([prefs objectForKey:@"disableNotificationGlow"] != nil)
        disableNotificationGlow = [[prefs objectForKey:@"disableNotificationGlow"] boolValue];
    else
        disableNotificationGlow = NO;

    if ([prefs objectForKey:@"requireBadge"] != nil)
        requireBadge = [[prefs objectForKey:@"requireBadge"] boolValue];
    else
        requireBadge = YES;

    if ([prefs objectForKey:@"disableRunningGlow"] != nil)
        disableRunningGlow = [[prefs objectForKey:@"disableRunningGlow"] boolValue];
    else
        disableRunningGlow = NO;

    if ([prefs objectForKey:@"disableUpdateGlow"] != nil)
        disableUpdateGlow = [[prefs objectForKey:@"disableUpdateGlow"] boolValue];
    else
        disableUpdateGlow = NO;

    if ([prefs objectForKey:@"updatedColor"] != nil)
        updatedColorMode = [[prefs objectForKey:@"updatedColor"] intValue];
    else
        updatedColorMode = 3;

    if ([prefs objectForKey:@"showDot"] != nil)
        showDot = [[prefs objectForKey:@"showDot"] boolValue];
    else
        showDot = YES;

    if ([prefs objectForKey:@"showDotInSwitcher"] != nil)
        showDotInSwitcher = [[prefs objectForKey:@"showDotInSwitcher"] boolValue];
    else
        showDotInSwitcher = YES;

    if ([prefs objectForKey:@"dotSize"] != nil)
        dotSize = [[prefs objectForKey:@"dotSize"] floatValue];
    else
        dotSize = 5;

    if ([prefs objectForKey:@"shiftDockUp"] != nil)
        shiftDockUp = [[prefs objectForKey:@"shiftDockUp"] boolValue];
    else
        shiftDockUp = YES;

    if ([prefs objectForKey:@"dotStyle"] != nil)
        dotStyle = (GBDotStyle)[[prefs objectForKey:@"dotStyle"] intValue];
    else
        dotStyle = GBDotStyleDark;

   if ([prefs objectForKey:@"disableBetaGlow"] != nil)
        disableBetaGlow = [[prefs objectForKey:@"disableBetaGlow"] boolValue];
    else
        disableBetaGlow = NO;

    if ([prefs objectForKey:@"betaColorMode"] != nil)
        betaColorMode = [[prefs objectForKey:@"betaColorMode"] intValue];
    else
        betaColorMode = 9;
}

SBIconView *getIconView(NSString *ident)
{
    SBIconView *ret = nil;
    if ([[[%c(SBIconViewMap) homescreenMap] iconModel] respondsToSelector:@selector(applicationIconForBundleIdentifier:)])
    {
        // iOS 8.0+

        SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:ident];
        ret = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
    }
    else
    {
        // iOS 7.X
        SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForDisplayIdentifier:ident];
        ret = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
    }
    return ret;
}

void updateGlowView(SBIconView *v, BOOL forceNotif = NO, BOOL isSwitcher = NO)
{
    const int dotTag = 2334;

    BOOL isBlacklisted = NO;
    if (v.icon.application)
    {
        NSString *identifier = v.icon.application.bundleIdentifier;
        if (prefs != nil && identifier != nil && [[prefs objectForKey: [@"Blacklist-" stringByAppendingString:identifier]] boolValue])
            isBlacklisted = YES;
    }

    if ((v.icon.application.isRunning == NO && v.icon.badgeValue == 0 && [ncIcons containsObject:v.icon] == NO && v.icon.application._isRecentlyUpdated == NO && v.icon.application._isNewlyInstalled == NO && iconIsBeta(v.icon) == NO)
    || ([suppressedIcons containsObject:v.icon] && isSwitcher == NO) 
    || enabled == NO 
    || ([v isKindOfClass:[%c(SBFolderIconView) class]] && glowFolders == NO) 
    || (glowDock == NO && [v isInDock])
    || (isSwitcher == YES && showInSwitcher == NO)
    || isBlacklisted
    )
    {
        [v._iconImageView.layer removeAnimationForKey:kGB_PulseAnimKey];
        [v.layer removeAnimationForKey:kGB_NotifAnimKey];
        v._iconImageView.layer.shadowOpacity = 0;
        [[v viewWithTag:dotTag] removeFromSuperview];
        return;
    }

    // "dot" under label
    if (v.icon.application.isRunning && showDot && [v isInDock]) // && (showDotInSwitcher ? (isSwitcher || [v isInDock]) : NO))
    {
        if ([v viewWithTag:dotTag] == nil)
        {
            UIView *dotView = [[UIView alloc] init];
            dotView.frame = CGRectMake((v.frame.size.width / 2) - (dotSize / 2), v.frame.size.height + (shiftDockUp || isSwitcher ? 2 : 0), dotSize, dotSize);
            dotView.tag = dotTag;
            dotView.clipsToBounds = YES;


            if (dotStyle == GBDotStyleDark)
                dotView.backgroundColor = [UIColor blackColor];
            else if (dotStyle == GBDotStyleLight)
                dotView.backgroundColor = [UIColor whiteColor];
            else if (dotStyle == GBDotStyleLightBlur)
            {
                UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
                UIView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
                blurView.frame = (CGRect){ {0, 0}, dotView.frame.size };
                [dotView addSubview:blurView];
            }
            else if (dotStyle == GBDotStyleExtraLightBlur)
            {
                UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
                UIView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
                blurView.frame = (CGRect){ {0, 0}, dotView.frame.size };
                [dotView addSubview:blurView];
            }
            else if (dotStyle == GBDotStyleDarkBlur)
            {
                UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                UIView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
                blurView.frame = (CGRect){ {0, 0}, dotView.frame.size };
                [dotView addSubview:blurView];
            }

            CGPoint saveCenter = dotView.center;
            dotView.layer.cornerRadius = dotSize / 2.0;
            dotView.center = saveCenter;

            //SBIconLabelView *_labelView;
            //[MSHookIvar<SBIconLabelView*>(v, "_labelView") addSubView:dotView];
            [v addSubview:dotView];
        }
        else
        {
            UIView *dotView = [v viewWithTag:dotTag];
            dotView.frame = CGRectMake((v.frame.size.width / 2) - (dotSize / 2), v.frame.size.height + (shiftDockUp || isSwitcher  ? 2 : 0), dotSize, dotSize);

            CGPoint saveCenter = dotView.center;
            dotView.layer.cornerRadius = dotSize / 2.0;
            dotView.center = saveCenter;
        }
    }
    else
    {
        [[v viewWithTag:dotTag] removeFromSuperview];
    }

    // pulse animation (for badge/running)
    if ([v._iconImageView.layer animationForKey:kGB_PulseAnimKey] == nil && animateGlow)
    {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        animation.fromValue = @.2;
        animation.toValue = @1;
        animation.repeatCount = INFINITY;
        animation.duration = 1.2;
        animation.autoreverses = YES;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [v._iconImageView.layer addAnimation:animation forKey:kGB_PulseAnimKey];
        v._iconImageView.layer.shadowOpacity = 1;
    }
    else if (!animateGlow)
    {
        [v._iconImageView.layer removeAnimationForKey:kGB_PulseAnimKey];
    }

    v._iconImageView.layer.shadowRadius = 13;
    v._iconImageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:v._iconImageView.layer.bounds].CGPath;
    v._iconImageView.layer.shadowColor = getColor(v._iconImageView).CGColor; // This is handled later in the CALayer hook also
    
    
    if (((v.icon.badgeValue != 0 || [ncIcons containsObject:v.icon]) && disableNotificationGlow && v.icon.application.isRunning == NO && iconIsBeta(v.icon) == NO)
    || (v.icon.application.isRunning && disableRunningGlow)
    || ((v.icon.application._isRecentlyUpdated || v.icon.application._isNewlyInstalled) && disableUpdateGlow)
    || (iconIsBeta(v.icon) && disableBetaGlow)
    )
    {
        v._iconImageView.layer.shadowOpacity = 0;
        v._iconImageView.layer.shadowColor = [UIColor clearColor].CGColor;
        [v._iconImageView.layer removeAnimationForKey:kGB_PulseAnimKey];
    }

    // grow animation for a badge
    if ((v.icon.badgeValue > 0 || [ncIcons containsObject:v.icon] || forceNotif) && animateNotifications)
    {
        if ([v.layer animationForKey:kGB_NotifAnimKey] != nil)
            return;

        CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
        animationGroup.duration = 3.5;
        animationGroup.repeatCount = INFINITY;

        CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        transformAnimation.toValue=[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1)];
        transformAnimation.duration = 0.5;
        transformAnimation.autoreverses = YES;
        transformAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        animationGroup.animations = @[transformAnimation];
        
        if ([v isInDock] && bounceDock)
        {
            const int factors_count = 44;
            // https://github.com/Cocoanetics/Examples/blob/master/IconBouncing/bouncetest/CAKeyFrameAnimation%2BJumping.m#L59-L83
            CGFloat factors[factors_count] = {0, 32, 60, 83, 100, 114, 124, 128, 128, 124, 114, 100, 83, 60, 32, 0, -5, -5,
                                   24, 46, 60, 66, 70, 66, 60, 46, 24, 0, -5, -5, 
                                   18, 28, 32, 28, 18, 0, -5, -5,
                                   16, 24, 16, 0,
                                   -5,
            };


            NSMutableArray *values = [NSMutableArray array];
            int iconHeight = 80;

            for (int i=0; i<factors_count; i++)
            {
                CGFloat positionOffset = factors[i]/128.0f * iconHeight;

                CATransform3D transform = CATransform3DMakeTranslation(0, -positionOffset, 0);
                [values addObject:[NSValue valueWithCATransform3D:transform]];
            }

            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
            animation.repeatCount = 0; // 1
            animation.duration = (CGFloat)factors_count/30.0f;
            animation.fillMode = kCAFillModeForwards;
            animation.values = values;
            animation.autoreverses = NO;

            animationGroup.animations = @[animation];
        }

        [v.layer addAnimation:animationGroup forKey:kGB_NotifAnimKey];
    }
    else
    {
        [v.layer removeAnimationForKey:kGB_NotifAnimKey];
    }
}

%hook SBIconView
-(void) layoutSubviews
{
    %orig;

    updateGlowView(self);
}
%end

%hook SBApplication
- (void)setApplicationState:(unsigned int)arg1
{
    %orig;

    NSString *ident = [self respondsToSelector:@selector(displayIdentifier)] ? [self displayIdentifier] : [self bundleIdentifier];
    getIconView(ident);
}

- (void)setRunning:(_Bool)arg1 // iOS 7 only
{
    %orig;

    NSString *ident = [self respondsToSelector:@selector(displayIdentifier)] ? [self displayIdentifier] : [self bundleIdentifier];
    getIconView(ident);
}

- (void)markRecentlyUpdated
{
    %orig;

    NSString *ident = [self respondsToSelector:@selector(displayIdentifier)] ? [self displayIdentifier] : [self bundleIdentifier];
    getIconView(ident);
}

- (void)markNewlyInstalled
{
    %orig;

    NSString *ident = [self respondsToSelector:@selector(displayIdentifier)] ? [self displayIdentifier] : [self bundleIdentifier];
    getIconView(ident);
}
%end

%hook SBIconViewMap
- (void)_addIconView:(SBIconView *)iconView forIcon:(SBIcon *)icon
{
	%orig;

    updateGlowView(iconView, NO, self != [%c(SBIconViewMap) homescreenMap]);
}

- (id)mappedIconViewForIcon:(id)arg1
{
    SBIconView *iconView = %orig;

    updateGlowView(iconView, NO, self != [%c(SBIconViewMap) homescreenMap]);
    return iconView;
}

- (void)iconViewDidChangeLocation:(SBIconView*)arg1
{
    %orig;
    
    [arg1._iconImageView.layer removeAnimationForKey:kGB_PulseAnimKey];
    [arg1.layer removeAnimationForKey:kGB_NotifAnimKey];
    arg1._iconImageView.layer.shadowOpacity = 0;
    updateGlowView(arg1);
}
%end

%hook SBIcon
-(void) noteBadgeDidChange
{
    %orig;

    [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:self];
}
%end

// APEX 2
BOOL oldAnimNotifs;
%hook STKGroupView
- (void)_animateOpenWithCompletion:(id)arg1
{ 
    %orig;
    for (SBIconView *view in self.subappLayout.allIcons)
    {
        SBIcon *icon = view.icon;
        if ([suppressedIcons containsObject:icon])
        {
            [suppressedIcons removeObject:icon];
            updateGlowView(view);
        }
    }

    oldAnimNotifs = animateNotifications; animateNotifications = NO;
    SBIconView *center = MSHookIvar<SBIconView*>(self, "_centralIconView");
    updateGlowView(center);
}

- (void)_animateClosedWithCompletion:(id)arg1
{ 
    %orig;
    for (SBIconView *view in self.subappLayout.allIcons)
    {
        SBIcon *icon = view.icon;
        if ([suppressedIcons containsObject:view.icon] == NO)
        {
            [suppressedIcons addObject:icon];
            updateGlowView(view);
        }
    }

    animateNotifications = oldAnimNotifs;
    SBIconView *center = MSHookIvar<SBIconView*>(self, "_centralIconView");
    updateGlowView(center);
}
%end

// Required for A U X O 2 to work, right now. 
BOOL AUXO2 = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Umino.dylib"];
%hook CALayer
-(CGColorRef) shadowColor
{
    if (!AUXO2)
        return %orig;
        
    if ([self.delegate isKindOfClass:[%c(SBIconImageView) class]])
    {
        SBIconImageView *view = (SBIconImageView*)self.delegate;
        if ((view.icon.application.isRunning == NO && view.icon.badgeValue == 0 && [ncIcons containsObject:view.icon] == NO) && view.icon.application._isRecentlyUpdated == NO && view.icon.application._isNewlyInstalled == NO)
            return %orig;

        UIColor *color = getColor(view);

        return color.CGColor;
    }
    return %orig;
}
%end

%hook BBServer
- (void)publishBulletin:(BBBulletin*)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(_Bool)arg3
{
    %orig;
    
    if (requireBadge)
        return;

    NSString *id = arg1.sectionID;
    SBIcon *icon = nil;
    if ([[[%c(SBIconViewMap) homescreenMap] iconModel] respondsToSelector:@selector(applicationIconForBundleIdentifier:)])
        icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:id];
    else
        icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForDisplayIdentifier:id];
    if (icon)
    {
        SBIconView *view = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
        [ncIcons addObject:icon];
        updateGlowView(view);
    }
}

- (void)_sendRemoveBulletins:(NSSet*)arg1 toFeeds:(unsigned long long)arg2 shouldSync:(_Bool)arg3
{
    %orig;
    
    if (requireBadge)
        return;
    
    //RILog(@"_sendRemoveBulletin<s>: %@", arg1);

    BBBulletin *bulletin = [arg1 anyObject];
    if (!bulletin)
        return;

    NSString *section = bulletin.sectionID;

    NSArray *bulletins = [self noticesBulletinIDsForSectionID:section];

    SBIcon *icon = nil;
    if ([[[%c(SBIconViewMap) homescreenMap] iconModel] respondsToSelector:@selector(applicationIconForBundleIdentifier:)])
        icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:section];
    else
        icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForDisplayIdentifier:section];
    
    //RILog(@"bulletins: %@", bulletins);

    if (bulletins.count == 0 && icon)
    {
        [ncIcons removeObject:icon];
        [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
    }
}
%end

%hook SBDockIconListView
-(CGFloat)topIconInset { return shiftDockUp ? 10 : %orig; }
%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, &reloadSettings, CFSTR("com.efrederickson.glowboard/reloadSettings"), NULL, 0);
    suppressedIcons = [[NSMutableSet alloc] init];
    reloadSettings(NULL, NULL, NULL, NULL, NULL);

	%init;

	[pool drain];
}