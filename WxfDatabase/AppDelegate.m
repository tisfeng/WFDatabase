//
//  AppDelegate.m
//  WxfDatabase
//
//  Created by isfeng on 2017/12/17.
//  Copyright © 2017年 isfeng. All rights reserved.
//

#import "AppDelegate.h"
#import "WxfDatabase.h"
#import "MJExtension.h"
#import "MJUser.h"
#import "MJAd.h"
#import "MJStatus.h"
#import "MJStudent.h"
#import "MJStatusResult.h"
#import "MJBag.h"
#import "MJDog.h"
#import "MJBook.h"
#import "MJBox.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    object2keyValues();
    
    return YES;
}

/**
 *  模型 -> 字典
 */
void object2keyValues()
{
    // 1.新建模型
    MJUser *user = [[MJUser alloc] init]; NSMapTable;NSUserDefaults;
    user.name = @"Jack";
    user.icon = @"lufy.png";
    
    MJStatus *status = [[MJStatus alloc] init];
    status.user = user;
    status.text = @"今天的心情不错！";
    
    // 2.将模型转为字典
    NSDictionary *statusDict = status.mj_keyValues;
    MJExtensionLog(@"%@", statusDict);
    
    MJExtensionLog(@"%@", [status mj_keyValuesWithKeys:@[@"text"]]);
    
    // 3.新建多级映射的模型
    MJStudent *stu = [[MJStudent alloc] init];
    stu.ID = @"123";
    stu.oldName = @"rose";
    stu.nowName = @"jack";
    stu.desc = @"handsome";
    stu.nameChangedTime = @"2018-09-08";
    stu.books = @[@"Good book", @"Red book"];
    
    MJBag *bag = [[MJBag alloc] init];
    bag.name = @"小书包";
    bag.price = 205;
    stu.bag = bag;
    
    NSDictionary *stuDict = stu.mj_keyValues;
    MJExtensionLog(@"%@", stuDict);
    MJExtensionLog(@"%@", [stu mj_keyValuesWithIgnoredKeys:@[@"bag", @"oldName", @"nowName"]]);
    MJExtensionLog(@"%@", stu.mj_JSONString);
    
    [MJStudent mj_referenceReplacedKeyWhenCreatingKeyValues:NO];
    MJExtensionLog(@"\n模型转字典时，字典的key参考replacedKeyFromPropertyName等方法:\n%@", stu.mj_keyValues);
    
    
    NSString *tableName = @"stu";
//    WxfDatabase *store = [[WxfDatabase alloc] initDBWithName:@"test.db"];
    WxfDatabase *store = [WxfDatabase shareDatabase];
    [store createTableWithName:tableName];
    NSString *key = @"stu1";
    //    NSDictionary *userDic = @{@"id": @1, @"name": @"tangqiao", @"age": @30};
    [store putObject:stu withId:key intoTable:tableName];
    stu.ID = @"124";
    [store putObject:stu withId:@"stu2" intoTable:tableName];
    stu.ID = @"125";
    [store putObject:stu withId:@"stu3" intoTable:tableName];
    stu.ID = @"126";
    [store putObject:stu withId:@"stu6" intoTable:tableName];

    
    NSDictionary *queryUser = [store getObjectById:key fromTable:tableName];
    NSLog(@"query data result: %@", queryUser);
    MJStudent *newStu = [MJStudent mj_objectWithKeyValues:queryUser];
    MJExtensionLog(@"%@",newStu);

    NSArray *stuArr = [store getAllItemsFromTable:tableName];
    NSArray *stuModleArr = [MJStudent mj_objectArrayWithKeyValuesArray:stuArr];
    NSLog(@"stuModleArr: %@",stuModleArr);
    
    NSDictionary *stu6Dic = [[WxfDatabase shareDatabase] getObjectById:@"stu6" fromTable:tableName];
    
    NSLog(@"stu6: %@",stu6Dic);
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
