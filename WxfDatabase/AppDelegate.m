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
    
    [self test];
    
    return YES;
}

/**
 *  YTKKeyValueStore + MJExtension
 */
- (void)test {
    
//    字典转模型
    NSDictionary *userDic = @{@"name":@"Jack",
                              @"icon":@"lufy.png"};
    MJUser *user = [MJUser mj_objectWithKeyValues:userDic];
    
//    多级模型嵌套映射
    MJStatus *status = [[MJStatus alloc] init];
    status.user = user;
    status.text = @"今天的心情不错！";
    
    MJBag *bag = [[MJBag alloc] init];
    bag.name = @"小书包";
    bag.price = 205;
    
//    初始化student模型
    MJStudent *stu = [[MJStudent alloc] init];
    stu.ID = @"123";
    stu.oldName = @"rose";
    stu.nowName = @"jack";
    stu.desc = @"handsome";
    stu.nameChangedTime = @"2018-09-08";
    stu.books = @[@"Good book", @"Red book"];

    stu.bag = bag;
    
    
    NSString *test_table = @"test";
    WxfDatabase *database = [WxfDatabase shareDatabase];
    [database createTableWithName:test_table];

    [database putObject:@"999" withKey:@"999" intoTable:test_table];
    [database putObject:@666 withKey:@"666" intoTable:test_table];
    NSString *string = [database getObjectByKey:@"999" fromTable:test_table];
    NSNumber *num = [database getObjectByKey:@"666" fromTable:test_table];
    
//    若使用MJExtension，存储的object类型是NSString或NSNumber，取出时类型会变成NSDecimalNumber
//    NSString *string = [[database getObjectByKey:@"999" fromTable:test_table] stringValue];
//    NSNumber *num = [NSNumber numberWithLong:[[database getObjectByKey:@"666" fromTable:test_table] longValue]];
    
//    这种方式存储NSString、NSNumber正常
    [database putNumber:@55 withKey:@"55" intoTable:test_table];
    [database putString:@"44" withKey:@"44" intoTable:test_table];
    NSString *string2 = [database getStringByKey:@"44" fromTable:test_table];
    NSNumber *num2 = [database getNumberByKey:@"55" fromTable:test_table];
   
    NSLog(@"string(%@): %@, num(%@): %@\n string2(%@): %@, num2(%@): %@",NSStringFromClass(string.class),string, NSStringFromClass(num.class),num,NSStringFromClass(string2.class),string2,NSStringFromClass(num2.class),num2);
    
//    存取字典
    NSDictionary *dict = @{@"id": @1, @"name": @"tangqiao", @"age": @30};
    [database putObject:dict withKey:@"dict" intoTable:test_table];
    NSDictionary *dict2 = [database getObjectByKey:@"dict" fromTable:test_table];
    NSLog(@"dict: %@",dict2);

//    存取数组
    NSArray *arr = @[@"123",@"array",@99,@{@"key":@"value"},[NSNumber numberWithBool:YES]];
    [database putObject:arr withKey:@"arr" intoTable:test_table];
    NSArray *arr2 = [database getObjectByKey:@"arr" fromTable:test_table];
    NSLog(@"arr: %@",arr2);
    
//    新建student表
    NSString *stu_table = @"student";
    [database createTableWithName:stu_table];
    
//    存取对象（将对象转成字典，序列化存储数据库）
    [database putObject:stu withKey:@"stu" intoTable:stu_table];
//    取对象
    MJStudent *student = [database getObjectByKey:@"stu" fromTable:stu_table];
    NSLog(@"student(%@): %@", NSStringFromClass(student.class),student);
    
    stu.ID = @"124";
    [database putObject:stu withKey:@"stu4" intoTable:stu_table];
    stu.ID = @"125";
    [database putObject:stu withKey:@"stu5" intoTable:stu_table];
    stu.ID = @"126";
    [database putObject:stu withKey:@"stu6" intoTable:stu_table];
    stu.ID = @"127";
    [database putObject:stu withKey:@"stu7" intoTable:stu_table];
    stu.ID = @"128";
    [database putObject:stu withKey:@"stu8" intoTable:stu_table];
    stu.ID = @"129";
    [database putObject:stu withKey:@"s9" intoTable:stu_table];

//    查询表元素个数
    NSUInteger stu_count = [database getCountFromTable:stu_table];
    NSLog(@"stu_count: %lu",(unsigned long)stu_count);
//    查询表中的所有object
    NSArray *stuModleArr = [database getAllObjectsFromTable:stu_table];
    NSLog(@"stuModleArr: %@",stuModleArr);
    
//    修改key值为stu的元素数据
    NSLog(@"stu.ID=%@",stu.ID);
    stu.ID = @"12345";
    [database putObject:stu withKey:@"stu" intoTable:stu_table];
    MJStudent *stu12345 = [database getObjectByKey:@"stu" fromTable:stu_table];
    NSLog(@"stu.ID=%@",stu12345.ID);
    
//    删除key为stu4的元素
    [database deleteObjectByKey:@"stu4" fromTable:stu_table];
    
//    删除数组中key的元素
    [database deleteObjectsByKeyArray:@[@"stu5",@"stu6"] fromTable:stu_table];
    
//    删除key前缀为stu的元素
    [database deleteObjectsByKeyPrefix:@"stu" fromTable:stu_table];
    
//    删除表
    [database dropTable:stu_table];
    
//    test
    NSArray *modleArr = @[stu,stu,stu,stu];
    [database putObject:modleArr withKey:@"modleAee" intoTable:test_table];
    NSLog(@"modleArr: %@",modleArr);
}


@end
