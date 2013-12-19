//
//  CWSettings.m
//  Copyright (c) 2013 com.randrup. All rights reserved.
//


#import "CWSettings.h"
#import <objc/runtime.h>

@interface CWSettings ()
@end

@implementation CWSettings {
    NSMutableDictionary *_classNames; //Avoiding use of @properties
    NSMutableDictionary *_notificationBlocks;
}

#pragma mark - Lazy Instantation
#define CLASS_NAMES_STORAGE @"SetttingsClockNameStorage"

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

#pragma mark - Setup/Teardown

+ (instancetype)sharedSettings
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

- (void)setup
{
//    NSString *filePath = [self filePathWithSettingName:@"backgroundColor"];
//    [self archiveObject:[UIColor blueColor] ofClass:@"UIColor" withFilePath:filePath];
    
    unsigned int numberOfProperties;
    objc_property_t *propertyArray = class_copyPropertyList([self class], &numberOfProperties);
    
    for (NSUInteger i = 0; i < numberOfProperties; i++) {
        objc_property_t property = propertyArray[i];
        NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];

        const char *attributes = property_getAttributes(property);
        /* Attribute string - "T@"UIImage",&,N,V_backgroundImage"
         * T@"UIImage" - T + @encode type
         * & - retain
         * N - nonatomic
         * V_backgroundImage - V + backinginstancevariable
         */
        
        class_replaceMethod([self class], NSSelectorFromString(name), (IMP)newGetter, attributes);
        
        NSString *setterName = [self setterForGetter:name];
//        class_replaceMethod([self class], NSSelectorFromString(setterName), (IMP)newSetter, attributes);
        
        Method setter = class_getInstanceMethod([self class], NSSelectorFromString(setterName));
        method_setImplementation(setter, (IMP)newSetter);
        const char *setterAttributes = method_getTypeEncoding(setter);
        
        class_replaceMethod([self class], NSSelectorFromString(setterName), (IMP)newSetter, setterAttributes);
        
        NSString *getterAttributes = [NSString stringWithUTF8String:attributes];
        NSString *className = [getterAttributes componentsSeparatedByString:@"\""][1]; //The class name inside the quotation marks. "UIImage" -> UIImage
        [self setClass:className forProperty:name];
    }
}

#pragma mark - Storing/Retreiving Data

- (NSString *)filePathWithSettingName:(NSString *)settingName //Tested
{
    NSMutableString *cleanString = [[settingName lowercaseString] mutableCopy];
    if ([cleanString hasPrefix:@"set"]) {
        [cleanString deleteCharactersInRange:NSMakeRange(0, 3)];
        [cleanString deleteCharactersInRange:NSMakeRange([cleanString length] - 1, 1)];
    }
    static NSString *writeableDirectoryPath = nil;
    if (writeableDirectoryPath == nil) writeableDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [writeableDirectoryPath stringByAppendingPathComponent:settingName];
    return filePath;
}

- (id)retreiveObjectOfClass:(NSString *)classString withFilePath:(NSString *)filePath
{
    if ([classString isEqualToString:NSStringFromClass([UIImage class])]) {
        return [UIImage imageNamed:filePath];
    }
    else if ([classString isEqualToString:NSStringFromClass([UIColor class])]) { //Tested
        return [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    }
    else if ([classString isKindOfClass:[NSArray class]]) {
        return [NSArray arrayWithContentsOfFile:filePath];
    }
    else if ([classString isKindOfClass:[NSDictionary class]]) {
        return [NSDictionary dictionaryWithContentsOfFile:filePath];
    }
    else return nil;
}

- (void)archiveObject:(id)object ofClass:(NSString *)classString withFilePath:(NSString *)filePath
{
    if ([classString isEqualToString:NSStringFromClass([UIImage class])]) {
        NSData *imageData = UIImagePNGRepresentation(object);
        [NSKeyedArchiver archiveRootObject:imageData toFile:filePath];
    }
    else if ([classString isEqualToString:NSStringFromClass([UIColor class])]) { //Tested
        [NSKeyedArchiver archiveRootObject:object toFile:filePath];
    }
    else if ([classString isEqualToString:NSStringFromClass([NSArray class])]) {
        NSArray *array = (NSArray *)object;
        [array writeToFile:filePath atomically:YES];
    }
    else if ([classString isEqualToString:NSStringFromClass([NSDictionary class])]) {
        NSDictionary *dictionary = (NSDictionary *)object;
        [dictionary writeToFile:filePath atomically:YES];
    }
//    else if ([objectClass isEqualToString:NSStringFromClass([ class])]) {
//        
//    }

}

#pragma mark - Setters and Getters

//Tested
- (NSString *)getterForSetter:(NSString *)setter                                      //setName:
{
    NSMutableString *getterString = [[setter lowercaseString] mutableCopy];           //setname:
    [getterString deleteCharactersInRange:NSMakeRange(0, 3)];                         //name:
    [getterString deleteCharactersInRange:NSMakeRange([getterString length] - 1, 1)]; //name
    return getterString;
}

//Tested
- (NSString *)setterForGetter:(NSString *)getter                              //Name
{
    NSMutableString *setterString = [[getter capitalizedString] mutableCopy]; //Name
    [setterString insertString:@"set" atIndex:0];                             //setName
    [setterString appendString:@":"];                                         //setName:
    return setterString;
}

//Tested
id newGetter(id self, SEL _cmd) {
    NSString *getterName = NSStringFromSelector(_cmd);
    NSString *className = [self classNameForPropertyName:getterName];
    NSString *filePath = [self filePathWithSettingName:getterName];
    return [self retreiveObjectOfClass:className withFilePath:filePath];;
}
 
void newSetter(id self, SEL _cmd, id newValue) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    NSString *className = [self classNameForPropertyName:getterName];
    NSString *filePath = [self filePathWithSettingName:setterName];
    [self archiveObject:newValue ofClass:className withFilePath:filePath];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             (unsigned long)NULL), ^(void) {
        [[self notificationBlocks] enumerateKeysAndObjectsUsingBlock:^(NSString *key, void(^ChangedSettingBlock)(id changedSetting) , BOOL *stop) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ChangedSettingBlock(newValue);
            });
        }];
    });
}

#pragma mark - Notifications

- (void)setNotificationBlock:(void(^)(id changedSetting))notificationBlock forPropertyNamed:(NSString *)propertyName
{
    [[self notificationBlocks] setObject:[notificationBlock copy] forKey:propertyName];
}

@end
