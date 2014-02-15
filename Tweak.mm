#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

@interface SBFolder : NSObject
-(id)indexPathForIconWithIdentifier:(id)identifier;
-(id)indexPathForIcon:(id)icon;
-(id)iconAtIndexPath:(id)indexPath;
@end

@interface SBIconController : NSObject
+(id)sharedInstance;
-(void)scrollToIconListContainingIcon:(id)iconListContainingIcon animate:(BOOL)animate;
-(id)rootFolder;
-(void)openFolder:(id)folder animated:(BOOL)animated;
-(id)openFolder;
-(BOOL)hasOpenFolder;
-(void)closeFolderAnimated:(BOOL)animated;
-(id)_currentFolderController;
@end

@interface SBIcon : NSObject
-(id)folder;
-(BOOL)isFolderIcon;
-(id)application;
-(id)displayName;
@end

@interface SBFolderController : NSObject
-(BOOL)setCurrentPageIndexToListContainingIcon:(id)listContainingIcon animated:(BOOL)animated;
@end

@interface SBSearchViewController : UIViewController {
	UITableView* _tableView;
}
+(id)sharedInstance;
-(void)loadView;
-(void)dismiss;
-(void)privateBlinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed accumulatedTime:(NSTimeInterval)accumulatedTime hideOrShow:(BOOL)hide;
-(void)blinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed;
@end

@interface SPSearchResultSection
-(id)resultsAtIndex:(unsigned int)arg1;
@end

@interface SPSearchAgent : NSObject
- (id)sectionAtIndex:(unsigned int)arg1;
@end

@interface SBSearchModel : SPSearchAgent
+(id)sharedInstance;
@end

@interface SPSearchResult
@property(readonly) BOOL hasUrl;
@property(retain) NSString * url; //Application identifier on iOS 7
-(BOOL)hasUrl;
-(NSString *)url;
@end

@interface SBIconImageView : UIView
@end

@interface SBIconViewMap : NSObject
+(id)homescreenMap;
-(id)iconViewForIcon:(id)icon;
@end

%hook SBSearchViewController

-(void)loadView {
    %orig;

    UITableView *_tableView = CHIvar(self, _tableView, UITableView *);
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1.5;
    [_tableView addGestureRecognizer:longPress];
    [longPress release];
}

%new
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    UITableView *_tableView = CHIvar(self, _tableView, UITableView *);

    CGPoint p = [gestureRecognizer locationInView:_tableView];

    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:p];
    if (indexPath && [indexPath length] == 2) {
        UIMenuController *menuController = [%c(UIMenuController) sharedMenuController];
        if (menuController.menuVisible) {
            [menuController setMenuVisible:NO animated:NO];
        }

        SBSearchModel *searchModel = [%c(SBSearchModel) sharedInstance];

        SPSearchResultSection *section = [searchModel sectionAtIndex:[indexPath indexAtPosition:0]];

        if (section) {
            SPSearchResult *result = [section resultsAtIndex:[indexPath indexAtPosition:1]];

            if (result && result.hasUrl) {
                NSString *appId = result.url;
                NSLog(@"Locate application icon with identifier: %@", appId);

                SBIconController *iconController = [%c(SBIconController) sharedInstance];

                SBFolder *rootFolder = [iconController rootFolder];
                NSIndexPath *appIndexPath = [rootFolder indexPathForIconWithIdentifier:appId];

                if (appIndexPath) {
                    [self dismiss];

                    if ([iconController hasOpenFolder])
                        [iconController closeFolderAnimated:NO];

                    for (int i=[appIndexPath length]; i>-1; i--) {
                        NSIndexPath *childIndexPath = appIndexPath;
                        for (int j=0; j<i; j++) {
                            childIndexPath = [childIndexPath indexPathByRemovingLastIndex];
                        }
                        SBIcon *icon = [rootFolder iconAtIndexPath:childIndexPath];
                        if (icon) {
                            [iconController scrollToIconListContainingIcon:icon animate:NO];
                            if ([icon isFolderIcon]) {
                                [iconController openFolder:[icon folder] animated:NO];
                            }
                            if (i == 0) {
                                SBFolderController *folderController = [iconController _currentFolderController];
                                if (folderController) {
                                    [folderController setCurrentPageIndexToListContainingIcon:icon animated:NO];
                                }
                                SBIconViewMap *iconMap = [%c(SBIconViewMap) homescreenMap];
                                if (iconMap) {
                                    SBIconImageView *iconView = [iconMap iconViewForIcon:icon];
                                    if (iconView) {
                                        [self blinkView:iconView duration:1.2 speed:0.3];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

//If the icon's alpha is changed by some other tweak
static CGFloat originalAlpha, newAlpha;

/* https://github.com/frowing/UIView-blink/blob/master/UIView%2BBlink.m */
%new
-(void)privateBlinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed accumulatedTime:(NSTimeInterval)accumulatedTime hideOrShow:(BOOL)hide {
    [UIView animateWithDuration:speed animations:^{
        view.alpha = hide ? newAlpha : originalAlpha;
    }

    completion:^(BOOL finished) {
        if (accumulatedTime >= duration) {
            view.alpha = originalAlpha;
        } else {
            [self privateBlinkView:view duration:duration speed:speed accumulatedTime:(accumulatedTime + speed) hideOrShow:!hide];
        }
    }];
}

%new
- (void)blinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed {
    originalAlpha = view.alpha;
    newAlpha = originalAlpha >= 0.5f ? 0.0f : 1.0f;

    [UIView animateWithDuration:speed animations:^{
        view.alpha = newAlpha;
    }

    completion:^(BOOL finished) {
        [self privateBlinkView:view duration:duration speed:speed accumulatedTime:0.0f hideOrShow:YES];
    }];
}

%end
