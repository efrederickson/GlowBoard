#import "SpringBoard.h"
#import <UIKit/UIBezierPath.h>
#import "Apex/STKGroupView.h"
#import "Apex/STKGroup.h"
#import "Apex/STKGroupLayout.h"
struct STKGroupSlot {
    unsigned long long position;
    unsigned long long index;
};
#import <UIKit/UIScreen.h>

#define RILog(fmt, ...) NSLog((@"[GlowBoard] " fmt), ##__VA_ARGS__)

NSMutableSet *suppressedIcons;

BOOL enabled = YES;
BOOL showInSwitcher = YES;
BOOL glowDock = YES;
BOOL animateNotifications = YES;
BOOL glowFolders = NO;
BOOL bounceDock = YES;
BOOL animateGlow = YES;
UIColor *badgedColor = [UIColor redColor];
UIColor *activeColor = [UIColor whiteColor];

void reloadSettings(CFNotificationCenterRef center,
                                    void *observer,
                                    CFStringRef name,
                                    const void *object,
                                    CFDictionaryRef userInfo)
{
    NSDictionary *prefs = [NSDictionary 
        dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.efrederickson.glowboard.settings.plist"];

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
    {
        int color = [[prefs objectForKey:@"activeColor"] intValue];
        if (color == 0)
            activeColor = [UIColor whiteColor];
        else if (color == 1)
            activeColor = [UIColor greenColor];
        else if (color == 2)
            activeColor = [UIColor redColor];
        else if (color == 3)
            activeColor = [UIColor blueColor];
    }
    else
        activeColor = [UIColor whiteColor];
        

    if ([prefs objectForKey:@"badgedColor"] != nil)
    {
        int color = [[prefs objectForKey:@"badgedColor"] intValue];
        if (color == 0)
            badgedColor = [UIColor whiteColor];
        else if (color == 1)
            badgedColor = [UIColor greenColor];
        else if (color == 2)
            badgedColor = [UIColor redColor];
        else if (color == 3)
            badgedColor = [UIColor blueColor];
    }
    else
        badgedColor = [UIColor redColor];
}

void updateGlowView(SBIconView *v)
{
    if (((SpringBoard *)[UIApplication sharedApplication]).isLocked)
        return;

    if (!enabled)
        return;
        
    if ([v isKindOfClass:[%c(SBFolderIconView) class]] && glowFolders == NO)
        return;

    if (glowDock == NO && [v isInDock])
        return;

    if ((v.icon.application.isRunning == NO && v.icon.badgeValue == 0) || [suppressedIcons containsObject:v.icon])
    {
        [v._iconImageView.layer removeAnimationForKey:@"pulse"];
        [v.layer removeAnimationForKey:@"transform"];
        v._iconImageView.layer.shadowOpacity = 0;
        return;
    }

    // pulse animation (for badge/running)
    if ([v._iconImageView.layer animationForKey:@"pulse"] == nil && animateGlow)
    {
        [v._iconImageView.layer removeAnimationForKey:@"pulse"];
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        animation.fromValue = @0.2; // .1
        animation.toValue = @1;
        animation.repeatCount = INFINITY;
        animation.duration = 1.2; // 1.2
        animation.autoreverses = YES;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [v._iconImageView.layer addAnimation:animation forKey:@"pulse"];

        v._iconImageView.layer.shadowOpacity = 1;
    }
    else if (!animateGlow)
    {
        [v._iconImageView.layer removeAnimationForKey:@"pulse"];
        v._iconImageView.layer.shadowOpacity = 1;
    }

    v._iconImageView.layer.shadowRadius = 15;
    v._iconImageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:v._iconImageView.layer.bounds].CGPath;
    v._iconImageView.layer.shadowColor = (v.icon.application.isRunning ? activeColor : badgedColor).CGColor;

    // grow animation for a badge
    if (v.icon.badgeValue > 0)
    {
        if ([v.layer animationForKey:@"transform"] != nil)
            return;

        [v.layer removeAnimationForKey:@"transform"];
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
            // https://github.com/Cocoanetics/Examples/blob/master/IconBouncing/bouncetest/CAKeyFrameAnimation%2BJumping.m#L59-L83
            //CGFloat factors[32] = {0, 32, 60, 83, 100, 114, 124, 128, 128, 124, 114, 100, 83, 60, 32,
            //    0, 24, 42, 54, 62, 64, 62, 54, 42, 24, 0, 18, 28, 32, 28, 18, 0};
                
            CGFloat factors[36] = {0, 32, 60, 83, 100, 114, 124, 128, 128, 124, 114, 100, 83, 60, 32, 0, 
                                   24, 46, 60, 66, 70, 66, 60, 46, 24, 0, 
                                   18, 28, 32, 28, 18, 0, 
                                   16, 24, 16, 0};


            NSMutableArray *values = [NSMutableArray array];

            int iconHeight = 80;

            for (int i=0; i<36; i++)
            {
                CGFloat positionOffset = factors[i]/128.0f * iconHeight;

                CATransform3D transform = CATransform3DMakeTranslation(0, -positionOffset, 0);
                [values addObject:[NSValue valueWithCATransform3D:transform]];
            }

            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
            animation.repeatCount = 0; // 1
            animation.duration = 36.0f/30.0f;
            animation.fillMode = kCAFillModeForwards;
            animation.values = values;
            animation.autoreverses = NO;

            animationGroup.animations = @[animation];
        }

        [v.layer addAnimation:animationGroup forKey:@"transform"];
    }
    else
    {
        [v.layer removeAnimationForKey:@"transform"];
    }
}

void ApplicationLaunched(SBApplication *application)
{
    if (!enabled)
        return;

	SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForDisplayIdentifier:[application displayIdentifier]];
	if (icon) 
    {
		[[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
	}
}

void ApplicationDied(SBApplication *application)
{
    if (!enabled)
        return;

	SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForDisplayIdentifier:[application displayIdentifier]];
	if (icon) {
		[[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
	}
}

%hook SBApplication
- (void)setRunning:(_Bool)arg1
{
    %orig;

    if (arg1)
        ApplicationLaunched(self);
    else
        ApplicationDied(self);
}
%end

%hook SBIconViewMap
- (void)_addIconView:(SBIconView *)iconView forIcon:(SBIcon *)icon
{
	%orig;

	if ((icon.application.isRunning || icon.badgeValue != 0) && (showInSwitcher || self == [%c(SBIconViewMap) homescreenMap]))
    {
        updateGlowView(iconView);
    }
}

- (id)mappedIconViewForIcon:(id)arg1
{
    SBIconView *iconView = %orig;
    updateGlowView(iconView);
    return iconView;
}
%end

%hook SBIcon
-(void) noteBadgeDidChange
{
    %orig;
    
    if (!animateNotifications)
        return;

    [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:self];
}
%end

// APEX 2
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
            if (icon)
                updateGlowView(view);
        }
    }
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
            if (icon)
                updateGlowView(view);
        }
    }
}
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