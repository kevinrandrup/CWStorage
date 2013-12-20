//
//  ColorPickerButton.m
//  Copyright (c) 2013 Kevin Randrup. All rights reserved.
//

#import "ColorPickerButton.h"
#import "NEOColorPickerViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ColorPickerButton () <NEOColorPickerViewControllerDelegate>
@property (nonatomic) UIPopoverController *popover;
@end

@implementation ColorPickerButton

#pragma mark - Setup/Teardown

- (void)setup
{
    [self addTarget:self action:@selector(pickColor:) forControlEvents:UIControlEventTouchUpInside];
    self.layer.cornerRadius = 10.0f;
    self.clipsToBounds = YES;
}

- (void)awakeFromNib
{
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    self.parent = nil;
    self.popover = nil;
}

#pragma mark - Picking Color

- (BOOL)isIPad
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

- (void)pickColor:(ColorPickerButton *)sender
{
    NEOColorPickerViewController *colorPicker = [[NEOColorPickerViewController alloc] init];
    colorPicker.delegate = self;
    colorPicker.selectedColor = self.backgroundColor;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:colorPicker];
    if ([self isIPad]) {
        if ([self.popover isPopoverVisible]) {
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
        }
        else {
            self.popover = [[UIPopoverController alloc] initWithContentViewController:navController];
            [self.popover presentPopoverFromRect:sender.frame inView:self.parent.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
    else [self.parent presentViewController:navController animated:YES completion:nil];
}

#pragma mark - Color Picker Delegate

- (void)dismissColorPicker
{
    if ([self isIPad]) [self.popover dismissPopoverAnimated:YES];
    else [self.parent dismissViewControllerAnimated:YES completion:nil];
}

- (void)colorPickerViewController:(NEOColorPickerBaseViewController *)controller didSelectColor:(UIColor *)color
{
    self.PickedColorBlock(color);
    [self dismissColorPicker];
}

- (void)colorPickerViewControllerDidCancel:(NEOColorPickerBaseViewController *)controller
{
    [self dismissColorPicker];
}

@end
