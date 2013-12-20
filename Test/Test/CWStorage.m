//
//  CWStorage.m
//  Copyright (c) 2013 Kevin Randrup. All rights reserved.
//


#import "CWStorage.h"
#import <objc/runtime.h>

@interface CWStorage ()
@end

@implementation CWStorage {
    NSMutableDictionary *_classNames; //Avoiding use of @properties
    NSMutableDictionary *_notificationBlocks;
    id <CWCustomClassStorage>_customClassStorageDelegate;
}

#pragma mark - Instance variable setters and getters

#define CLASS_NAMES_STORAGE @"CWStorageClassNameStorage"

//Creating getters and setters here to avoid use of @properties

- (NSMutableDictionary *)classNames
{
    if (_classNames == nil) {
        _classNames = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:CLASS_NAMES_STORAGE] mutableCopy];
        if (_classNames == nil) _classNames = [NSMutableDictionary dictionary];
    }
    return _classNames;
}

- (NSMutableDictionary *)notificationBlocks
{
    if (_notificationBlocks == nil) _notificationBlocks = [NSMutableDictionary dictionary];
    return _notificationBlocks;
}

- (id)customClassStorageDelegate
{
    return _customClassStorageDelegate;
}

- (void)setCustomClassStorageDelegate:(id<CWCustomClassStorage>)customClassStorageDelegate
{
    _customClassStorageDelegate = customClassStorageDelegate;
}

#pragma mark - Setup/Teardown

+ (instancetype)sharedStorage
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance setup];
    });
    return sharedInstance;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSString *)classNameForPropertyName:(NSString *)propertyName
{
    NSString *className = [self classNames][propertyName];
    return className;
}

- (void)setClass:(NSString *)class forProperty:(NSString *)propertyName
{
    [[self classNames] setObject:class forKey:propertyName];
}

//Iterates through all properties, and replaces their implementations
- (void)setup
{
    unsigned int numberOfProperties;
    objc_property_t *propertyArray = class_copyPropertyList([self class], &numberOfProperties);
    
    for (NSUInteger i = 0; i < numberOfProperties; i++) {
        objc_property_t property = propertyArray[i];
        
        const char *attributes = property_getAttributes(property);
        
        NSString *getterName = [[NSString alloc] initWithUTF8String:property_getName(property)];

        Method getter = class_getInstanceMethod([self class], @selector(newGetter));
        IMP getterImplementation = method_getImplementation(getter);
        SEL originalGetterMethodSelector = NSSelectorFromString(getterName);
        Method originalGetterMethod = class_getInstanceMethod([self class], originalGetterMethodSelector);
        method_setImplementation(originalGetterMethod, getterImplementation);
        
        
        NSString *setterName = [self setterForGetter:getterName];
        
        Method setter = class_getInstanceMethod([self class], @selector(newSetter:));
        IMP setterImplementation = method_getImplementation(setter);
        SEL originalSetterMethodSelector = NSSelectorFromString(setterName);
        Method originalSetterMethod = class_getInstanceMethod([self class], originalSetterMethodSelector);
        method_setImplementation(originalSetterMethod, setterImplementation);
        
        NSString *getterAttributes = [NSString stringWithUTF8String:attributes];
        NSString *className = [getterAttributes componentsSeparatedByString:@"\""][1]; //The class name inside the quotation marks. "UIImage" -> UIImage
        [self setClass:className forProperty:getterName];
    }
}

#pragma mark - Storing/Retreiving Data

- (NSString *)filePathForPropertyName:(NSString *)getterName
{
    static NSString *writeableDirectoryPath = nil;
    if (writeableDirectoryPath == nil) writeableDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [writeableDirectoryPath stringByAppendingPathComponent:getterName];
    return filePath;
}

- (id)retreiveObjectOfClass:(NSString *)classString withFilePath:(NSString *)filePath
{
    id returnObject = nil;
    Class class = NSClassFromString(classString);
    if ([class conformsToProtocol:@protocol(NSCoding)]) {
        returnObject = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    else if (self.customClassStorageDelegate) {
        returnObject = [self.customClassStorageDelegate retreiveObjectOfClass:classString withFilePath:filePath];
    }
    return returnObject;
}

- (void)archiveObject:(id)object ofClass:(NSString *)classString withFilePath:(NSString *)filePath
{
    if ([object conformsToProtocol:@protocol(NSCoding)]) {
        [NSKeyedArchiver archiveRootObject:object toFile:filePath];
    }
    else if (self.customClassStorageDelegate) {
        [self.customClassStorageDelegate archiveObject:object ofClass:classString withFilePath:filePath];
    }
}

#pragma mark - Setters and Getters

- (NSString *)getterForSetter:(NSString *)setter                                           //setName:
{
    NSMutableString *getterString = [setter mutableCopy];                                  //setName:
    [getterString deleteCharactersInRange:NSMakeRange(0, 3)];                              //Name:
    NSString *firstCharacter = [[getterString substringToIndex:1] lowercaseString];        //n
    NSRange firstCharacterRange = NSMakeRange(0, 1);
    [getterString replaceCharactersInRange:firstCharacterRange withString:firstCharacter]; //name:
    NSRange colonRange = NSMakeRange([getterString length] - 1, 1);
    [getterString deleteCharactersInRange:colonRange];                                     //name
    return getterString;
}

- (NSString *)setterForGetter:(NSString *)getter                                           //name
{
    NSMutableString *setterString = [getter mutableCopy];                                  //name
    NSString *firstCharacter = [[getter substringToIndex:1] capitalizedString];            //N
    [setterString replaceCharactersInRange:NSMakeRange(0, 1) withString:firstCharacter];   //Name
    [setterString insertString:@"set" atIndex:0];                                          //setName
    [setterString appendString:@":"];                                                      //setName:
    return setterString;
}

//Generic setter
- (void)newSetter:(id)newValue
{
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    NSString *className = [self classNameForPropertyName:getterName];
    NSString *filePath = [self filePathForPropertyName:getterName];
    [self archiveObject:newValue ofClass:className withFilePath:filePath];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:[self notificationNameForPropertyName:getterName] object:self userInfo:@{getterName:newValue}];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             (unsigned long)NULL), ^(void) {
        [[self notificationBlocks] enumerateKeysAndObjectsUsingBlock:^(NSString *key, void(^ChangedSettingBlock)(id changedSetting) , BOOL *stop) {
            if ([key isEqualToString:getterName]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ChangedSettingBlock(newValue);
                });
            }
        }];
    });
}

//Generic getter
- (id)newGetter
{
    NSString *getterName = NSStringFromSelector(_cmd);
    NSString *className = [self classNameForPropertyName:getterName];
    NSString *filePath = [self filePathForPropertyName:getterName];
    return [self retreiveObjectOfClass:className withFilePath:filePath];;
}

#pragma mark - Notifications

- (NSString *)notificationNameForPropertyName:(NSString *)propertyName
{
    return [NSString stringWithFormat:@"CWStoragePropertyWasSet - %@", propertyName];
}

- (void)setNotificationBlock:(void(^)(id changedSetting))notificationBlock forPropertyName:(NSString *)propertyName
{
    [[self notificationBlocks] setObject:[notificationBlock copy] forKey:propertyName];
}

@end