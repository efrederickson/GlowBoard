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

@interface PSListItemsController (GlowBoard)
- (void)setIsRestrictionList:(BOOL)arg1;
- (BOOL)isRestrictionList;
- (id)itemsFromDataSource;
- (id)itemsFromParent;
- (void)_addStaticText:(id)arg1;
- (void)listItemSelected:(id)arg1;
- (void)setRowToSelect;
- (void)setValueForSpecifier:(id)arg1 defaultValue:(id)arg2;
- (void)scrollToSelectedCell;
- (void)didLock;
- (void)prepareSpecifiersMetadata;
- (id)specifiers;
- (void)dealloc;
- (void)suspend;
- (void)viewWillDisappear:(BOOL)arg1;
- (void)viewWillAppear:(BOOL)arg1;
- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2;
@end
@interface PSTableCell (GLowBoard)
- (id)titleLabel;
- (void)setIcon:(id)arg1;
- (BOOL)isChecked;
- (id)iconImageView;
- (void)setType:(int)arg1;
- (int)type;
- (id)title;
- (void)setCellEnabled:(BOOL)arg1;
- (void)setValue:(id)arg1;
- (void)setSeparatorStyle:(int)arg1;

- (id)titleTextLabel;
- (id)value;
- (UILabel *)valueLabel;
@end

@interface GBActualSettingsListController : SKTintedListController<SKListControllerProtocol>
@end
@interface GBMakersListController : SKTintedListController<SKListControllerProtocol>
@end
@interface ElijahPersonCell : SKPersonCell
@end
@interface AndrewPersonCell : SKPersonCell
@end
@interface GBColorSelectorController : PSListItemsController
@end

@interface GBSettingsListController: SKStandardController
@end
@implementation GBSettingsListController
-(BOOL) showHeartImage { return YES; }
-(BOOL) tintNavigationTitleText { return NO; }
-(BOOL) shiftHeartImage { return YES; }
-(NSString*) shareMessage { return @"I’m loving #GlowBoard by @daementor!"; }
-(NSString*) headerText { return @"GlowBoard"; }
-(NSString*) headerSubText { return @"Give your icons a heavenly glow"; }

-(NSString*) customTitle { return @""; }
-(NSString*) plistName { return @"GlowBoardSettings"; }

-(NSString*)postNotification { return @"com.efrederickson.glowboard/reloadSettings"; }
-(NSString*)defaultsFileName { return @"com.efrederickson.glowboard.settings"; }
-(NSArray*) emailAddresses { return @[@"elijah.frederickson+glowboard@gmail.com", @"andrewaboshartworks+glowboard@gmail.com"]; }
-(NSString*) emailBody { return @""; }
-(NSString*) emailSubject { return @"GlowBoard"; }
-(NSString*) enabledDescription { return @"Quickly enable or disable GlowBoard."; }

-(UIColor*) iconColor { return [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f]; }
-(UIColor*) headerColor { return [UIColor colorWithRed:74/255.0f green:74/255.0f blue:74/255.0f alpha:1.0f]; }
-(UIColor*) heartImageColor { return [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f]; }
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f]; }


-(NSString*) settingsListControllerClassName { return @"GBActualSettingsListController"; }
-(NSString*) makersListControllerClassName { return @"GBMakersListController"; }

-(NSString*) footerText { return @"© 2014 Elijah Frederickson & Andrew Abosh"; }
@end

@implementation GBActualSettingsListController
-(NSString*) plistName { return @"GlowBoardSettings"; }
-(NSString*) customTitle { return @"GlowBoard"; }
-(BOOL) showHeartImage { return NO; }
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f]; }
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
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f]; }
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

@implementation GBColorSelectorController
- (void)viewWillAppear:(BOOL)animated {
    self.view.tintColor = [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f];;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:38/255.0f green:166/255.0f blue:141/255.0f alpha:1.0f];;
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
    self.view.tintColor = nil;
    self.navigationController.navigationBar.tintColor = nil;
}

- (id)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {
	PSTableCell *cell = [super tableView:arg1 cellForRowAtIndexPath:arg2];
	NSString *title = [[cell titleLabel] text];
	[cell.imageView setImage:[UIImage imageNamed:[title stringByAppendingString:@".png"] inBundle:[NSBundle bundleForClass:self.class]]];
	return cell;
}
@end