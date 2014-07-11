#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"

@interface GlowBoardFlipswitchSwitch : NSObject <FSSwitchDataSource>
@end

@implementation GlowBoardFlipswitchSwitch

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.efrederickson.glowboard.settings.plist"];

    if ([prefs objectForKey:@"enabled"] != nil)
        return [[prefs objectForKey:@"enabled"] boolValue] ? FSSwitchStateOn : FSSwitchStateOff;
    else
        return FSSwitchStateOn;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	if (newState == FSSwitchStateIndeterminate)
		return;
        
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.efrederickson.glowboard.settings.plist"];

    prefs[@"enabled"] = newState == FSSwitchStateOn ? @YES : @NO;
    
    [prefs writeToFile:@"/var/mobile/Library/Preferences/com.efrederickson.glowboard.settings.plist" atomically:YES];
}

@end