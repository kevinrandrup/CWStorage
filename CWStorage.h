//
//  CWStorage.h
//  Copyright (c) 2013 Kevin Randrup. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CWCustomClassStorage;

@interface CWStorage : NSObject

+ (instancetype)sharedStorage;

//Properties will be lazily instantiated to their saved value
//Properties will be saved when they are set. A notification will also be posted and a notifcation block will be called if it exists.



//Declare properties here (must conform to NSCoding)




//Notifications are called after the object has been archived.
- (void)setNotificationBlock:(void(^)(id changedSetting))notificationBlock forPropertyName:(NSString *)propertyName;

//The newValue of the property is included in the user info under the key of the property name.
- (NSString *)notificationNameForPropertyName:(NSString *)propertyName;

- (void)setCustomClassStorageDelegate:(id<CWCustomClassStorage>)customClassStorageDelegate;

@end


//Use this protocol to override an implementation for classes that do not implement NSCoding already
@protocol CWCustomClassStorage <NSObject>
@required
- (void)archiveObject:(id)object ofClass:(NSString *)classString withFilePath:(NSString *)filePath;
- (id)retreiveObjectOfClass:(NSString *)classString withFilePath:(NSString *)filePath;
@end