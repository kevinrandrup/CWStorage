//
//  ViewController.m
//  Copyright (c) 2013 Kevin Randrup. All rights reserved.
//

#import "ViewController.h"
#import "CWStorage.h"
#import "ColorPickerButton.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet ColorPickerButton *backgroundColorButton;
@property (nonatomic) CWStorage *settings;

@end

@implementation ViewController

- (CWStorage *)settings
{
    if (_settings == nil) _settings = [CWStorage sharedStorage];
    return _settings;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the background color to the value saved in CWSettings
    [self.view setBackgroundColor:self.settings.backgroundColor];
    
    //This block will be called when the color of the button is changed by the ColorPickerButton class
    //This is used to demonstrate the setter.
    [self.backgroundColorButton setPickedColorBlock:^(UIColor *pickedColor) {
        [self.settings setBackgroundColor:pickedColor];
    }];
    
    __block ViewController *blockSelf = self;
    
    //The notification block will be called after setBackgroundColor: is called.
    [self.settings setNotificationBlock:^(id changedSetting) {
        blockSelf.view.backgroundColor = changedSetting;
    } forPropertyName:@"backgroundColor"];
}

@end
