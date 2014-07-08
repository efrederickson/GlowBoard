#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <SettingsKit/SKStandardController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>

@interface PSTableCell (GlowBoard)
@property (nonatomic, retain) UIView *backgroundView;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
@end

@interface PSListController (GlowBoard)
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;
-(UINavigationController*)navigationController;
@end

@interface GBActualSettingsListController : SKTintedListController<SKListControllerProtocol>
@end
@interface GBMakersListController : SKTintedListController<SKListControllerProtocol>
@end
@interface ElijahPersonCell : SKPersonCell
@end
@interface AndrewPersonCell : SKPersonCell
@end

@interface GBSettingsListController: SKStandardController
@end
@implementation GBSettingsListController
-(BOOL) showHeartImage { return YES; }
-(BOOL) tintNavigationTitleText { return NO; }
-(BOOL) shiftHeartImage { return YES; }
-(NSString*) shareMessage { return @"I’m loving #GlowBoard!"; }
-(NSString*) headerText { return @"GlowBoard"; }
-(NSString*) headerSubText { return @"Give your icons a heavenly glow"; }

-(NSString*) customTitle { return @""; }
-(NSString*) plistName { return @"GlowBoardSettings"; }

-(NSString*)postNotification { return @"com.efrederickson.glowboard/reloadSettings"; }
-(NSString*)defaultsFileName { return @"com.efrederickson.glowboard.settings"; }
-(NSArray*) emailAddresses { return @[@"elijah.frederickson@gmail.com", @"andrewaboshartworks@gmail.com"]; }
-(NSString*) emailBody { return @""; }
-(NSString*) emailSubject { return @"GlowBoard"; }
-(NSString*) enabledDescription { return @"Quickly enable or disable GlowBoard."; }

-(UIColor*) iconColor { return [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f]; }
-(UIColor*) headerColor { return [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f]; }
-(UIColor*) heartImageColor { return [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f]; }
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f]; }


-(NSString*) settingsListControllerClassName { return @"GBActualSettingsListController"; }
-(NSString*) makersListControllerClassName { return @"GBMakersListController"; }

-(NSString*) footerText { return @"© 2014 Elijah Frederickson"; }
@end

@implementation GBActualSettingsListController
-(NSString*) plistName { return @"GlowBoardSettings"; }
-(NSString*) customTitle { return @"GlowBoard"; }
-(BOOL) showHeartImage { return NO; }
@end

@implementation  ElijahPersonCell
-(NSString*)personDescription { return @"The Developer"; }
-(NSString*)name { return @"Elijah Frederickson"; }
-(NSString*)twitterHandle { return @"daementor"; }
-(NSString*)imageName { return @"elijah.png"; } /* should be a circular image, 200x200 retina */
@end

@implementation AndrewPersonCell
-(NSString*)personDescription { return @"The Designer"; }
-(NSString*)name { return @"Andrew Abosh"; }
-(NSString*)twitterHandle { return @"drewplex"; }
-(NSString*)imageName { return @"andrew.png"; } /* should be a circular image, 200x200 retina */
@end

@implementation GBMakersListController
-(BOOL) showHeartImage { return NO; }
-(NSString*) customTitle { return @"The Makers"; }

- (id)customSpecifiers {
    return @[
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"cellClass": @"ElijahPersonCell",
                 @"height": @100,
                 @"action": @"openElijahTwitter"
                 },
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"cellClass": @"AndrewPersonCell",
                 @"height": @100,
                 @"action": @"openAndrewTwitter"
                 },
             @{ @"cell": @"PSGroupCell" },
             @{
                 @"cell": @"PSLinkCell",
                 @"label": @"Source Code",
                 @"action": @"openGithub",
                 @"icon": @"github.png"
                 },
             ];
}

-(void) openGithub
{
    [SKSharedHelper openGitHub:@"mlnlover11/GlowBoard"];
}

-(void) openElijahTwitter
{
    [SKSharedHelper openTwitter:@"daementor"];
}

-(void) openAndrewTwitter
{
    [SKSharedHelper openTwitter:@"drewplex"];
}
@end
