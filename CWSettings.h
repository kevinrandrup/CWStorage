//
//  CWSettings.h
//  Copyright (c) 2013 com.randrup. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CWSettings : NSObject

+ (instancetype)sharedSettings;

@property (nonatomic) UIImage *backgroundImage;

@property (nonatomic) UIColor *backgroundColor;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) UIColor *spokesColor;

- (void)setNotificationBlock:(void(^)(id changedSetting))notificationBlock forPropertyNamed:(NSString *)propertyName;

@end
