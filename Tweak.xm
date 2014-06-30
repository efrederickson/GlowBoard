#import "SpringBoard.h"
#import <UIKit/UIBezierPath.h>
#import "Apex/STKGroupView.h"
#import "Apex/STKGroup.h"
#import "Apex/STKGroupLayout.h"

#define RILog(fmt, ...) NSLog((@"[GlowBoard] " fmt), ##__VA_ARGS__)

NSMutableSet *runningIcons;
NSMutableSet *badgedIcons;
NSMutableSet *suppressedIcons;

BOOL enabled = YES;
BOOL showInSwitcher = YES;
BOOL glowDock = YES;
BOOL animateNotifications = YES;
BOOL glowFolders = NO;
BOOL bounceDock = YES;
UIColor *badgedColor = [UIColor redColor]; //[UIColor colorWithHexString:@"ae5252"];
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

UIView *getOrCreateGlowView(SBIconView *v)
{
    if (!enabled)
        return nil;
        
    if ([v isKindOfClass:[%c(SBFolderIconView) class]] && glowFolders == NO)
        return nil;

    if (glowDock == NO && [v isInDock])
        return nil;

    UIView *view;
    if ([v viewWithTag:1337] != nil)
    {
        view = [v viewWithTag:1337];
    }
    else
    {
        CGRect frame = v._iconImageView.visibleBounds;
        view = [[UIView alloc] initWithFrame:CGRectMake(frame.origin.x - 3, frame.origin.y - 3, frame.size.width + 5, frame.size.height + 5)];
        view.tag = 1337;
        view.layer.cornerRadius = 15;
        //[v insertSubview:view atIndex:4];
        int index = [v.subviews indexOfObject:v._iconImageView];
        if (index >= 0)
            [v insertSubview:view atIndex:index-1];
        //[v insertSubView:view beforeSubview:v._iconImageView];
    }

    if (([runningIcons containsObject:v.icon] == NO && [badgedIcons containsObject:v.icon] == NO) || [suppressedIcons containsObject:v.icon])
    {
        [view removeFromSuperview];
        [view release];
        view = nil;
        [v.layer removeAnimationForKey:@"transform"];
        return nil;
    }

    view.backgroundColor = [UIColor clearColor];

    // pulse animation (for badge/running)
    if ([view.layer animationForKey:@"pulse"] == nil)
    {
    [view.layer removeAnimationForKey:@"pulse"];
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @0.2; // .1
    animation.toValue = @1;
    animation.repeatCount = INFINITY;
    animation.duration = 1; // 1.2
    animation.autoreverses = YES;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [view.layer addAnimation:animation forKey:@"pulse"];

    view.layer.shadowRadius = 10;
    view.layer.shadowColor = ([runningIcons containsObject:v.icon] ? activeColor : badgedColor).CGColor;
    view.layer.shadowOpacity = 1;
    view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
    }

    // grow animation for a badge
    if ([badgedIcons containsObject:v.icon])
    {
        if ([v.layer animationForKey:@"transform"] != nil)
            return view;

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

            int iconHeight = 90;

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

    return view;
}

void ApplicationLaunched(SBApplication *application)
{
    if (!enabled)
        return;

	SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForDisplayIdentifier:[application displayIdentifier]];
	if (icon) 
    {
		[runningIcons addObject:icon];
		[[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
	}
}

void ApplicationDied(SBApplication *application)
{
    if (!enabled)
        return;

	SBIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForDisplayIdentifier:[application displayIdentifier]];
	if (icon) {
		[runningIcons removeObject:icon];
		[[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
	}
}

%hook SBAppSliderController
- (void)_appActivationStateDidChange:(NSNotification *)notification
{
    %orig;

	SBApplication *app = notification.object;
	if ([app isRunning])
		ApplicationLaunched(app);
	else
		ApplicationDied(app);
}
%end

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

	if (([runningIcons containsObject:icon] || [badgedIcons containsObject:icon]) && (showInSwitcher || self == [%c(SBIconViewMap) homescreenMap]))
        getOrCreateGlowView(iconView);
}

- (id)mappedIconViewForIcon:(id)arg1
{
    SBIconView *iconView = %orig;
    getOrCreateGlowView(iconView);
    return iconView;
}
%end

%hook SBIcon
-(void) noteBadgeDidChange
{
    %orig;
    
    if (!animateNotifications)
        return;

    if (self.badgeValue == 0)
        [badgedIcons removeObject:self];
    else if (self.badgeValue > 0)
        [badgedIcons addObject:self];

    getOrCreateGlowView([[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:self]);
}
%end

%hook SBIconView
- (void)removeAllIconAnimations
{
    %orig;
    
    /*
    UIView *view = getOrCreateGlowView(self); 
    
    [view.layer removeAnimationForKey:@"pulse"];
    [view removeFromSuperview];
    [view release];
    [self.layer removeAnimationForKey:@"transform"];
    */
}
%end

// APEX 2
/*
%hook STKGroupView
- (void)_animateOpenWithCompletion:(id)arg1
{ %orig;
    for (SBIcon *icon in self.group.layout.allIcons)
    {
        [suppressedIcons removeObject:icon];
        getOrCreateGlowView([[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon]);
    }
}

- (void)_animateClosedWithCompletion:(id)arg1
{ %orig;
    for (SBIcon *icon in self.group.layout.allIcons)
    {
        [suppressedIcons addObject:icon];
        getOrCreateGlowView([[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon]);
    }
}
%end
*/

%hook STKGroupLayout
- (void)addIcon:(id)arg1 toIconsAtPosition:(unsigned long long)arg2 {
    %orig; 
    [suppressedIcons addObject:arg1];
}

- (void)removeIcon:(id)arg1 fromIconsAtPosition:(unsigned long long)arg2 {
    %orig;
    [suppressedIcons removeObject:arg1];
}
%end

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(r, NULL, &reloadSettings, CFSTR("com.efrederickson.glowboard/reloadSettings"), NULL, 0);

	%init;
	runningIcons = [[NSMutableSet alloc] init];
    badgedIcons = [[NSMutableSet alloc] init];
    suppressedIcons = [[NSMutableSet alloc] init];
    reloadSettings(NULL, NULL, NULL, NULL, NULL);
	[pool drain];
}