#import <UIKit/UIKit.h>
#import <CaptainHook/CaptainHook.h>

@interface SBFolder : NSObject
-(id)indexPathForIconWithIdentifier:(id)identifier;
-(id)indexPathForIcon:(id)icon;
-(id)iconAtIndexPath:(id)indexPath;
@end

@interface SBIconViewMap : NSObject
+(id)homescreenMap; //Deprecated in 9.3
-(id)iconViewForIcon:(id)icon;
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
-(SBIconViewMap *)homescreenIconViewMap; //New in 9.3
@end

@interface SBIcon : NSObject
-(id)folder;
-(BOOL)isFolderIcon;
-(id)application;
@end

@interface SBFolderController : NSObject
-(BOOL)setCurrentPageIndexToListContainingIcon:(id)listContainingIcon animated:(BOOL)animated;
@end

@interface SPSearchResultSection
-(id)resultsAtIndex:(unsigned int)arg1;
@end

@interface SPSearchAgent : NSObject
-(id)sectionAtIndex:(unsigned int)arg1;
@end

//Removed in iOS 9
@interface SBSearchModel : SPSearchAgent
+(id)sharedInstance;
@end

//New in iOS 9
@interface SPUISearchModel : SPSearchAgent
+(id)sharedInstance;
@end

@interface SPUISearchTableView : UITableView
@end

//New in iOS 9
@interface SPUISearchViewController : UIViewController {
    SPUISearchTableView *_tableView;
}
-(SPUISearchTableView *)searchTableView;
-(void)dismiss;
-(void)privateBlinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed accumulatedTime:(NSTimeInterval)accumulatedTime hideOrShow:(BOOL)hide;
-(void)blinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed;
@end

//iOS 7 & 8
@interface SBSearchViewController : UIViewController {
	UITableView* _tableView;
}
-(void)loadView;
-(void)dismiss;
-(void)privateBlinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed accumulatedTime:(NSTimeInterval)accumulatedTime hideOrShow:(BOOL)hide;
-(void)blinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed;
@end

@interface SPSearchResult
@property(readonly) BOOL hasUrl;
@property(retain) NSString * url; //Application identifier on iOS 7
-(BOOL)hasUrl;
-(NSString *)url;
@end

@interface SBIconImageView : UIView
@end

%group iOS78

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
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    //if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
    //    return;

    UITableView *_tableView = CHIvar(self, _tableView, UITableView *);

    CGPoint p = [gestureRecognizer locationInView:_tableView];

    NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:p];
    if (indexPath && [indexPath length] == 2) {
        UIMenuController *menuController = [%c(UIMenuController) sharedMenuController];
        if (menuController.menuVisible)
            [menuController setMenuVisible:NO animated:NO];

        SPSearchResultSection *section = [[%c(SBSearchModel) sharedInstance] sectionAtIndex:[indexPath indexAtPosition:0]];

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
                        for (int j=0; j<i; j++)
                            childIndexPath = [childIndexPath indexPathByRemovingLastIndex];

                        SBIcon *icon = [rootFolder iconAtIndexPath:childIndexPath];
                        if (icon) {
                            [iconController scrollToIconListContainingIcon:icon animate:NO];
                            if ([icon isFolderIcon])
                                [iconController openFolder:[icon folder] animated:NO];

                            if (i == 0) {
                                SBFolderController *folderController = [iconController _currentFolderController];
                                if (folderController)
                                    [folderController setCurrentPageIndexToListContainingIcon:icon animated:NO];

                                SBIconViewMap *iconMap = nil;
                                if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)])
                                    iconMap = [%c(SBIconViewMap) homescreenMap];
                                else if ([iconController respondsToSelector:@selector(homescreenIconViewMap)])
                                    iconMap = [iconController homescreenIconViewMap];
                                else
                                    ;

                                if (iconMap) {
                                    SBIconImageView *iconView = [iconMap iconViewForIcon:icon];
                                    if (iconView)
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

/* https://github.com/frowing/UIView-blink/blob/master/UIView%2BBlink.m */
%new
-(void)privateBlinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed accumulatedTime:(NSTimeInterval)accumulatedTime hideOrShow:(BOOL)hide {
    [UIView animateWithDuration:speed animations:^{
        view.alpha = hide ? 0.0f : 1.0f;
    }

    completion:^(BOOL finished) {
        if (accumulatedTime >= duration)
            view.alpha = 1.0f;
        else
            [self privateBlinkView:view duration:duration speed:speed accumulatedTime:(accumulatedTime + speed) hideOrShow:!hide];
    }];
}

%new
- (void)blinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed {
    [UIView animateWithDuration:speed animations:^{
        view.alpha = 0.0f;
    }

    completion:^(BOOL finished) {
        [self privateBlinkView:view duration:duration speed:speed accumulatedTime:0.0f hideOrShow:YES];
    }];
}

%end

%end //iOS 7 & 8

%group iOS9

%hook SPUISearchViewController

- (void)viewDidLoad {
    %orig;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1.5;
    [[self searchTableView] addGestureRecognizer:longPress];
    [longPress release];
}

%new
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    //if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
    //    return;

    SPUISearchTableView *tableView = [self searchTableView];

    CGPoint p = [gestureRecognizer locationInView:tableView];

    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:p];
    if (indexPath && [indexPath length] == 2) {
        UIMenuController *menuController = [%c(UIMenuController) sharedMenuController];
        if (menuController.menuVisible)
            [menuController setMenuVisible:NO animated:NO];

        SPSearchResultSection *section = [[%c(SPUISearchModel) sharedInstance] sectionAtIndex:[indexPath indexAtPosition:0]];

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
                        for (int j=0; j<i; j++)
                            childIndexPath = [childIndexPath indexPathByRemovingLastIndex];

                        SBIcon *icon = [rootFolder iconAtIndexPath:childIndexPath];
                        if (icon) {
                            [iconController scrollToIconListContainingIcon:icon animate:NO];
                            if ([icon isFolderIcon])
                                [iconController openFolder:[icon folder] animated:NO];

                            if (i == 0) {
                                SBFolderController *folderController = [iconController _currentFolderController];
                                if (folderController)
                                    [folderController setCurrentPageIndexToListContainingIcon:icon animated:NO];

                                SBIconViewMap *iconMap = nil;
                                if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)])
                                    iconMap = [%c(SBIconViewMap) homescreenMap];
                                else if ([iconController respondsToSelector:@selector(homescreenIconViewMap)])
                                    iconMap = [iconController homescreenIconViewMap];
                                else
                                    ;

                                if (iconMap) {
                                    SBIconImageView *iconView = [iconMap iconViewForIcon:icon];
                                    if (iconView)
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

%new
-(void)privateBlinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed accumulatedTime:(NSTimeInterval)accumulatedTime hideOrShow:(BOOL)hide {
    [UIView animateWithDuration:speed animations:^{
        view.alpha = hide ? 0.0f : 1.0f;
    }
 
    completion:^(BOOL finished) {
        if (accumulatedTime >= duration)
            view.alpha = 1.0f;
        else
            [self privateBlinkView:view duration:duration speed:speed accumulatedTime:(accumulatedTime + speed) hideOrShow:!hide];
    }];
}

%new
- (void)blinkView:(UIView *)view duration:(NSTimeInterval)duration speed:(NSTimeInterval)speed {
    [UIView animateWithDuration:speed animations:^{
        view.alpha = 0.0f;
    }
 
    completion:^(BOOL finished) {
        [self privateBlinkView:view duration:duration speed:speed accumulatedTime:0.0f hideOrShow:YES];
    }];
}

%end

%end //iOS9

%ctor {
    @autoreleasepool {
        if (kCFCoreFoundationVersionNumber < 1240.10)
            %init(iOS78);
        else
            %init(iOS9);
    }
}
