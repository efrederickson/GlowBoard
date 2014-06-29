#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>

@interface GBSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation GBSettingsListController
-(BOOL) tintNavigationTitleText { return NO; }
-(BOOL) showHeartImage { return NO; }
-(NSString*) headerText { return @"GlowBoard"; }
-(NSString*) headerSubText { return @"Give your icons a heavenly glow"; }

-(NSString*) customTitle { return @"GlowBoard"; }
-(NSString*) plistName { return @"GlowBoardSettings"; }
@end
