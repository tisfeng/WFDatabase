//
//  WxfDatabase.h
//  WxfDatabase
//
//  Created by isfeng on 2017/12/17.
//  Copyright © 2017年 isfeng. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 YTKKeyValueItem 模型是转化后，在SQLite数据库中存储存储的对象
 itemKey:       存储数据的主键
 itemObject:    存储对象序列化NSData
 createdTime:   数据存储时间戳
 */
@interface YTKKeyValueItem : NSObject

@property (strong, nonatomic) NSString *itemKey;
@property (strong, nonatomic) id itemObject;
@property (strong, nonatomic) NSDate *createdTime;

@end

@interface WxfDatabase : NSObject

/**
 快捷方法初始化默认数据库，document/database.sqlite
 */
+ (instancetype)shareDatabase;
+ (instancetype)shareDatabaseWithName:(NSString *)dbName;
+ (instancetype)shareDatabaseWithPath:(NSString *)dbPath;

/**
 新建或打开document目录下dbName数据库
 */
- (instancetype)initDBWithName:(NSString *)dbName;

/**
 新建或打开dbPath路径数据库
 */
- (instancetype)initDBWithPath:(NSString *)dbPath;

/**
 新建tableName表
 */
- (void)createTableWithName:(NSString *)tableName;

/**
 清空表数据
 */
- (void)clearTable:(NSString *)tableName;

/**
 删除表
 */
- (void)dropTable:(NSString *)tableName;

///************************ Put&Get methods *****************************************

/**
 存储一条数据到数据库

 @param object 存储的对象，可以是模型，字典或数组，或是NSString NSNumber等其他OC数据类型
 @param objectKey 存储时设置的key值，类似字典的key
 @param tableName 存储的数据表
 */
- (void)putObject:(id)object withKey:(NSString *)objectKey intoTable:(NSString *)tableName;

/**
 取值

 @param objectKey 根据key取值
 @param tableName 表名
 @return 返回存储的对象，前后数据类型不变
 */
- (id)getObjectByKey:(NSString *)objectKey fromTable:(NSString *)tableName;

/**
 获取该表中所有的元素

 @param tableName 表名
 @return 返回该表的object数组
 */
- (NSArray *)getAllObjectsFromTable:(NSString *)tableName;

/**
 查询表中元素个数

 @param tableName 表名
 @return 表中元素个数count
 */
- (NSUInteger)getCountFromTable:(NSString *)tableName;

/**
 根据key值删除表中某个数据
 */
- (void)deleteObjectByKey:(NSString *)objectKey fromTable:(NSString *)tableName;

/**
 删除表中包含key值数组的数据
 */
- (void)deleteObjectsByKeyArray:(NSArray *)objectKeyArray fromTable:(NSString *)tableName;

/**
 删除表中以key为前缀的数据
 */
- (void)deleteObjectsByKeyPrefix:(NSString *)objectKeyPrefix fromTable:(NSString *)tableName;

@end
