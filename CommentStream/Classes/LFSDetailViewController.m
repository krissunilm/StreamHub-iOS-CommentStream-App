//
//  LFSDetailViewController.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/13/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <StreamHub-iOS-SDK/NSDateFormatter+RelativeTo.h>
#import "LFSDetailViewController.h"
#import "LFSPostViewController.h"

@interface LFSDetailViewController ()

// render iOS7 status bar methods as writable properties
@property (nonatomic, assign) BOOL prefersStatusBarHidden;
@property (nonatomic, assign) UIStatusBarAnimation preferredStatusBarUpdateAnimation;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet LFSBasicHTMLLabel *basicHTMLLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet LFSBasicHTMLLabel *remoteUrlLabel;
@property (weak, nonatomic) IBOutlet UIButton *sourceButton;
@property (weak, nonatomic) IBOutlet UIToolbar *contentToolbar;
- (IBAction)didSelectSource:(id)sender;

@end

static const CGFloat kAvatarCornerRadius = 4;

static NSString* const kReplySegue = @"replyTo";

@implementation LFSDetailViewController {
    UIImage *_avatarImage;
}

#pragma mark - Class methods
static UIFont *titleFont = nil;
static UIFont *bodyFont = nil;
static UIFont *dateFont = nil;
static UIColor *dateColor = nil;

+ (void)initialize {
    if(self == [LFSDetailViewController class]) {
        titleFont = [UIFont boldSystemFontOfSize:16.f];
        bodyFont = [UIFont fontWithName:@"Georgia" size:17.0f];
        dateFont = [UIFont systemFontOfSize:13.f];
        dateColor = [UIColor lightGrayColor];
    }
}

#pragma mark - Properties

@synthesize scrollView = _scrollView;

@synthesize basicHTMLLabel = _basicHTMLLabel;

@synthesize avatarView = _avatarView;
@synthesize authorLabel = _authorLabel;
@synthesize dateLabel = _dateLabel;
@synthesize remoteUrlLabel = _remoteUrlLabel;
@synthesize contentToolbar = _contentToolbar;
@synthesize sourceButton = _sourceButton;

@synthesize hideStatusBar = _hideStatusBar;

// render iOS7 status bar methods as writable properties
@synthesize prefersStatusBarHidden = _prefersStatusBarHidden;
@synthesize preferredStatusBarUpdateAnimation = _preferredStatusBarUpdateAnimation;

-(void)setAvatarImage:(UIImage*)image
{
    _avatarImage = image;
}

#pragma mark - Lifecycle

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _hideStatusBar = NO;
    }
    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _hideStatusBar = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // set and format main content label
    [_basicHTMLLabel setDelegate:self];
    [_basicHTMLLabel setFont:bodyFont];
    [_basicHTMLLabel setLineSpacing:8.5f];
    
    [_basicHTMLLabel setHTMLString:[self.contentItem contentBodyHtml]];
    CGRect mainLabelFrame = _basicHTMLLabel.frame;
    CGSize maxSize = mainLabelFrame.size;
    maxSize.height = 1000.f;
    mainLabelFrame.size = [_basicHTMLLabel sizeThatFits:maxSize];
    [_basicHTMLLabel setFrame:mainLabelFrame];
    
    CGFloat bottom = mainLabelFrame.size.height + mainLabelFrame.origin.y;
    
    // set source icon
    if (self.contentItem.author.twitterHandle) {
        [_sourceButton setImage:[UIImage imageNamed:@"SourceTwitter"]
                       forState:UIControlStateNormal];
    }
    else {
        [_sourceButton setImage:nil
                       forState:UIControlStateNormal];
    }
    
    // format author name label
    [_authorLabel setFont:titleFont];
    
    // format date label
    [_dateLabel setFont:dateFont];
    [_dateLabel setTextColor:dateColor];
    CGRect dateFrame = _dateLabel.frame;
    dateFrame.origin.y = bottom + 12.f;
    [_dateLabel setFrame:dateFrame];

    
    // set and format url link
    [_remoteUrlLabel setTextAlignment:NSTextAlignmentRight];
    [_remoteUrlLabel setCenterVertically:YES]; // necessary for iOS6
    
    NSString *twitterURLString = [self.contentItem contentTwitterUrlString];
    if (twitterURLString != nil) {
        [_remoteUrlLabel setHTMLString:
         [NSString stringWithFormat:@"<a href=\"%@\">View on Twitter ></a>",
          twitterURLString]];
    }
    CGRect profileFrame = _remoteUrlLabel.frame;
    profileFrame.origin.y = bottom + 12.f;
    [_remoteUrlLabel setFrame:profileFrame];
    
    // set toolbar frame
    CGFloat extraOffsetForToolbar = 12.f;
    if (LFS_SYSTEM_VERSION_LESS_THAN(LFSSystemVersion70)) {
        extraOffsetForToolbar += 14.f;
        if (!self.hideStatusBar) {
            // status bar visible
            extraOffsetForToolbar += 12.f;
        }
    }
    CGRect toolbarFrame = _contentToolbar.frame;
    toolbarFrame.origin.y = dateFrame.origin.y + dateFrame.size.height + extraOffsetForToolbar;
    _contentToolbar.frame = toolbarFrame;

    // format avatar image view
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0f))
    {
        // Retina display, okay to use half-points
        CGRect avatarFrame = _avatarView.frame;
        avatarFrame.size = CGSizeMake(37.5f, 37.5f);
        [_avatarView setFrame:avatarFrame];
    }
    else
    {
        // non-Retina display, do not use half-points
        CGRect avatarFrame = _avatarView.frame;
        avatarFrame.size = CGSizeMake(37.f, 37.f);
        [_avatarView setFrame:avatarFrame];
    }
    _avatarView.layer.cornerRadius = kAvatarCornerRadius;
    _avatarView.layer.masksToBounds = YES;
    
    // set author name
    NSString *authorName = self.contentItem.author.displayName;
    [_authorLabel setText:authorName];

    
    // set date
    NSString *dateTime = [[[NSDateFormatter alloc] init]
                          extendedRelativeStringFromDate:
                          [self.contentItem contentCreatedAt]];
    [_dateLabel setText:dateTime];
    
    // set avatar image
    _avatarView.image = _avatarImage;
    
    // calculate content size
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width,
                                           _contentToolbar.frame.origin.y +
                                           _contentToolbar.frame.size.height + 20.f)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setStatusBarHidden:self.hideStatusBar withAnimation:UIStatusBarAnimationNone];
    //[self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Status bar

-(void)setStatusBarHidden:(BOOL)hidden
            withAnimation:(UIStatusBarAnimation)animation
{
    _prefersStatusBarHidden = hidden;
    _preferredStatusBarUpdateAnimation = animation;
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        // iOS 7
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    else
    {
        // iOS 6
        [[UIApplication sharedApplication] setStatusBarHidden:hidden
                                                withAnimation:animation];
        if (self.navigationController) {
            UINavigationBar *navigationBar = self.navigationController.navigationBar;
            if (hidden && navigationBar.frame.origin.y > 0.f) {
                CGRect frame = navigationBar.frame;
                frame.origin.y = 0;
                navigationBar.frame = frame;
            } else if (!hidden && navigationBar.frame.origin.y < 20.f) {
                CGRect frame = navigationBar.frame;
                frame.origin.y = 20.f;
                navigationBar.frame = frame;
            }
        }
    }
}

#pragma mark - OHAttributedLabelDelegate
-(BOOL)attributedLabel:(OHAttributedLabel*)attributedLabel
      shouldFollowLink:(NSTextCheckingResult*)linkInfo
{
    return YES;
}

-(UIColor*)attributedLabel:(OHAttributedLabel*)attributedLabel
              colorForLink:(NSTextCheckingResult*)linkInfo
            underlineStyle:(int32_t*)underlineStyle
{
    static NSString* const kTwitterSearchPrefix = @"https://twitter.com/#!/search/realtime/";
    NSString *linkString = [linkInfo.URL absoluteString];
    if ([linkString hasPrefix:kTwitterSearchPrefix])
    {
        // Twitter hashtag
        return [UIColor grayColor];
    }
    else
    {
        // regular link
        return [UIColor blueColor];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:kReplySegue])
    {
        // Get reference to the destination view controller
        if ([segue.destinationViewController isKindOfClass:[LFSPostViewController class]])
        {
            // as there is only one piece of content in Detail View,
            // no need to check sender type here
            LFSPostViewController *vc = segue.destinationViewController;
            [vc setCollection:self.collection];
            [vc setCollectionId:self.collectionId];
            [vc setReplyToContent:self.contentItem];
        }
    }
}

#pragma mark - Events
- (IBAction)didSelectSource:(id)sender
{
    NSString *urlString = self.contentItem.author.profileUrlStringNoHashBang;
    if (urlString != nil) {
        NSURL *url = [NSURL URLWithString:self.contentItem.author.profileUrlStringNoHashBang];
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
