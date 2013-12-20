//
//  ColorPickerButton.h
//  Copyright (c) 2013 Kevin Randrup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorPickerButton : UIButton

@property (nonatomic) IBOutlet UIViewController *parent;

@property (nonatomic, strong) void(^PickedColorBlock)(UIColor *pickedColor);
- (void)setPickedColorBlock:(void (^)(UIColor *pickedColor))PickedColorBlock;

@end
