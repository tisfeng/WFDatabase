//
//  WxfDatabase.m
//  WxfDatabase
//
//  Created by isfeng on 2017/12/17.
//  Copyright © 2017年 isfeng. All rights reserved.
//

#import "WFDatabase.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseAdditions.h"
#import "FastCoder.h"

#ifdef DEBUG
#define debugLog(...)    NSLog(__VA_ARGS__)
#define debugMethod()    NSLog(@"%s", __func__)
#define debugError()     NSLog(@"Error at %s Line:%d", __func__, __LINE__)
#else
#define debugLog(...)
#define debugMethod()
#define debugError()
#endif

// document目录
#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@implementation YTKKeyValueItem
- (NSString *)description {
    return [NSString stringWithFormat:@"key=%@, value=%@, timeStamp=%@", _itemKey, _itemObject, _createdTime];
}
@end


@interface WFDatabase ()
//@property (nonatomic, strong) YTKKeyValueItem *item;
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@end


@implementation WFDatabase

//默认数据库
static NSString *const DEFAULT_DB_NAME = @"database.sqlite";


/*
 建表
 key：标识主键
 dictData：序列化后的存储对象
 createdTime：时间戳
 */
static NSString *const CREATE_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS %@ ( \
key TEXT NOT NULL, \
dictData BLOL NOT NULL, \
createdTime TEXT NOT NULL, \
PRIMARY KEY(key)) \
";

//插入或修改数据
static NSString *const UPDATE_ITEM_SQL = @"REPLACE INTO %@ (key, dictData, createdTime) values (?, ?, ?)";
//根据key值查询数据
static NSString *const QUERY_ITEM_SQL = @"SELECT dictData, createdTime from %@ where key = ? Limit 1";
//查询表所有数据
static NSString *const SELECT_ALL_SQL = @"SELECT * from %@";
//查询表数据记录count
static NSString *const COUNT_ALL_SQL = @"SELECT count(*) as num from %@";
//清空表数据
static NSString *const CLEAR_ALL_SQL = @"DELETE from %@";
//根据key删除数据
static NSString *const DELETE_ITEM_SQL = @"DELETE from %@ where key = ?";
//根据key数组删除多条数据
static NSString *const DELETE_ITEMS_SQL = @"DELETE from %@ where key in ( %@ )";
//根据key前缀删除数据
static NSString *const DELETE_ITEMS_WITH_PREFIX_SQL = @"DELETE from %@ where key like ? ";
//删除表
static NSString *const DROP_TABLE_SQL = @" DROP TABLE '%@' ";


//  操作前对表作检查
+ (BOOL)checkTableName:(NSString *)tableName {
    if (tableName == nil ||
        tableName.length == 0 ||
        [tableName rangeOfString:@" "].location != NSNotFound)
    {
        debugLog(@"ERROR, table name: %@ format error.", tableName);
        return NO;
    }
    return YES;
}

/**
 快捷方法初始化默认数据库，document/database.sqlite
 */
+ (instancetype)shareDatabase {
    return [[self alloc] init];
}
+ (instancetype)shareDatabaseWithName:(NSString *)dbName {
    return [[self alloc] initDBWithName:dbName];
}
+ (instancetype)shareDatabaseWithPath:(NSString *)dbPath {
    return [[self alloc] initDBWithPath:dbPath];
}

/**
 默认初始化数据库
 */
- (instancetype)init {
    return [self initDBWithName:DEFAULT_DB_NAME];
}

/**
 新建或打开document目录下dbName数据库
 */
- (instancetype)initDBWithName:(NSString *)dbName {
    self = [super init];
    if (self) {
        NSString *dbPath = [PATH_OF_DOCUMENT stringByAppendingPathComponent:dbName];
        debugLog(@"dbPath = %@", dbPath);
        if (_dbQueue) {
            [self close];
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self;
}

/**
 新建或打开dbPath路径数据库
 */
- (instancetype)initDBWithPath:(NSString *)dbPath {
    self = [super init];
    if (self) {
        debugLog(@"dbPath = %@", dbPath);
        if (_dbQueue) {
            [self close];
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self;
}

/**
 新建tableName表
 */
- (void)createTableWithName:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return;
    }
    NSString *sql = [NSString stringWithFormat:CREATE_TABLE_SQL, tableName];
    __block BOOL result;
    
//    如果未指定数据库，则创建使用默认数据库...
    if (!_dbQueue) {
        NSString *dbPath = [PATH_OF_DOCUMENT stringByAppendingPathComponent:DEFAULT_DB_NAME];
        debugLog(@"未存在database,创建默认数据库dbPath = %@", dbPath);
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    if (!result) {
        debugLog(@"ERROR, failed to create table: %@", tableName);
    }
}

/**
 判断表是否已存在
 */
- (BOOL)isTableExists:(NSString *)tableName{
    if ([WFDatabase checkTableName:tableName] == NO) {
        return NO;
    }
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db tableExists:tableName];
    }];
    if (!result) {
        debugLog(@"ERROR, table: %@ not exists in current DB", tableName);
    }
    return result;
}

/**
 清空表数据（表还在）
 */
- (void)clearTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return;
    }
    NSString *sql = [NSString stringWithFormat:CLEAR_ALL_SQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    if (!result) {
        debugLog(@"ERROR, failed to clear table: %@", tableName);
    }
}

/**
 删除表
 */
- (void)dropTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return;
    }
    NSString *sql = [NSString stringWithFormat:DROP_TABLE_SQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    if (!result) {
        debugLog(@"ERROR, failed to drop table: %@", tableName);
    }
}

/**
 存储一条数据到数据库表
 
 @param object 存储的对象，可以是模型，字典或数组，或是NSString NSNumber等其他OC数据类型
 @param objectKey 存储时设置的key值，类似字典的key
 @param tableName 存储的数据表
 */
- (void)putObject:(id)object withKey:(NSString *)objectKey intoTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return;
    }
    NSError *error;
//    NSData * data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object]; //这种方式需要object对象支持归档
//    使用MJExtension,可将OC基础类型+自定义对象 序列化
#if 0
    if ([NSStringFromClass([object class]) isEqualToString:@"__NSCFNumber"]) {
//        data = [NSJSONSerialization dataWithJSONObject:@[object] options:0 error:&error];
//        data = [NSData dataWithBytes:&object length:sizeof(object)];
//        data = [NSKeyedArchiver archivedDataWithRootObject:object];
        NSString * stringNum = [NSString stringWithFormat:@"%@",object];
        data = [stringNum dataUsingEncoding:NSUTF8StringEncoding];
    } else {
        data = [object mj_JSONData]; 
    }
#endif
/*  考虑到MJ序列化有缺陷，使用系统NSJSONSerialization只能序列化字典或数组，对于NSString NSNumber类型需要自己再包装，容易导致前后存取类型不一致。自定义对象要先转为字典在序列化，后取出时需手动再转模型。   另外还发现，使用mj_JSONData序列化时调用的mj_keyValues方法在作第一层数据类型判断时，若为OC基础对象则会直接返回对象本身，也就是说MJ不能序列化自定义的对象数组。。。弃
 
    改用FastCoder对象序列化，更高效，且可使前后存取数据类型保持存取一致。赞！！！
 */
    NSData *data = [FastCoder dataWithRootObject:object];
    if (error) {
        debugLog(@"ERROR, faild to get dictData data");
        return;
    }
    
    NSDate *createdTime = [NSDate date];
    NSString *sql = [NSString stringWithFormat:UPDATE_ITEM_SQL, tableName];
    //    UPDATE_ITEM_SQL = @"REPLACE INTO %@ (id, json, createdTime) values (?, ?, ?)"
    __block BOOL result;
    
//    若不存在当前表，则创建...
    if (![self isTableExists:tableName]) {
        [self createTableWithName:tableName];
    }
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate: sql, objectKey, data, createdTime];
    }];
    if (!result) {
        debugLog(@"ERROR, failed to insert/replace into table: %@", tableName);
    }
}

/**
 取值
 
 @param objectKey 根据key取值
 @param tableName 表名
 @return 返回存储的对象，前后数据类型不变
 */
- (id)getObjectByKey:(NSString *)objectKey fromTable:(NSString *)tableName {
    YTKKeyValueItem *item = [self getYTKKeyValueItemByKey:objectKey fromTable:tableName];
    if (item) {
        return item.itemObject;
    } else {
        return nil;
    }
}

- (YTKKeyValueItem *)getYTKKeyValueItemByKey:(NSString *)objectKey fromTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return nil;
    }
    NSString *sql = [NSString stringWithFormat:QUERY_ITEM_SQL, tableName];
    //    __block NSString * json = nil;
    __block NSData *data = nil;
    __block NSDate *createdTime = nil;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql, objectKey];
        if ([rs next]) {
            data = [rs dataForColumn:@"dictData"];
            createdTime = [rs dateForColumn:@"createdTime"];
        }
        [rs close];
    }];
    if (data) {
        NSError *error;
//        id result = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingAllowFragments) error:&error];
//        result = [data mj_JSONObject];
//        result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//        将序列化数据包装成对象
        id result = [FastCoder objectWithData:data];
        if (error) {
            debugLog(@"ERROR, faild to prase to json");
            return nil;
        }
        YTKKeyValueItem *item = [[YTKKeyValueItem alloc] init];
        item.itemKey = objectKey;
        item.itemObject = result;
        item.createdTime = createdTime;
        return item;
    } else {
        return nil;
    }
}

/**
 存取NSString类型，把字符串对象包装成一个数组对象
 */
- (void)putString:(NSString *)string withKey:(NSString *)stringKey intoTable:(NSString *)tableName {
    if (string == nil) {
        debugLog(@"error, string is nil");
        return;
    }
    [self putObject:@[string] withKey:stringKey intoTable:tableName];
}
- (NSString *)getStringByKey:(NSString *)stringKey fromTable:(NSString *)tableName {
    NSArray *array = [self getObjectByKey:stringKey fromTable:tableName];
    if (array && [array isKindOfClass:[NSArray class]]) {
        return array[0];
    }
    return nil;
}

/**
 存取NSNumber类型，把数字对象包装成一个数组对象
 */
- (void)putNumber:(NSNumber *)number withKey:(NSString *)numberKey intoTable:(NSString *)tableName {
    if (number == nil) {
        debugLog(@"error, number is nil");
        return;
    }
    [self putObject:@[number] withKey:numberKey intoTable:tableName];
}
- (NSNumber *)getNumberByKey:(NSString *)numberKey fromTable:(NSString *)tableName {
    NSArray *array = [self getObjectByKey:numberKey fromTable:tableName];
    if (array && [array isKindOfClass:[NSArray class]]) {
        return array[0];
    }
    return nil;
}

/**
 获取该表中所有的元素
 
 @param tableName 表名
 @return 返回该表的object数组
 */
- (NSArray *)getAllObjectsFromTable:(NSString *)tableName {
    NSMutableArray *objectArr = [NSMutableArray array];
    NSArray *allItems = [self _getAllItemsFromTable:tableName];
    for (YTKKeyValueItem *item in allItems) {
        [objectArr addObject:item.itemObject];
    }
    return objectArr;
}

/**
 获取该表中所有的数据的YTKKeyValueItem对象（内部方法）
 
 @param tableName 表名
 @return 返回该表中数据的YTKKeyValueItem对象数组
 */
- (NSArray *)_getAllItemsFromTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return nil;
    }
    NSString *sql = [NSString stringWithFormat:SELECT_ALL_SQL, tableName];
    __block NSMutableArray *result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            YTKKeyValueItem *item = [[YTKKeyValueItem alloc] init];
            item.itemKey = [rs stringForColumn:@"key"];
            item.itemObject = [rs dataForColumn:@"dictData"];
            item.createdTime = [rs dateForColumn:@"createdTime"];
            [result addObject:item];
        }
        [rs close];
    }];
    // parse json string to object
    NSError *error;
    for (YTKKeyValueItem *item in result) {
        error = nil;
//        id object = [NSJSONSerialization JSONObjectWithData:item.itemObject options:(NSJSONReadingAllowFragments) error:&error];
        id object = [FastCoder objectWithData:item.itemObject];
        if (error) {
            debugLog(@"ERROR, faild to prase to json.");
        } else {
            item.itemObject = object;
        }
    }
    return result;
}

/**
 查询表中元素个数
 
 @param tableName 表名
 @return 表中元素个数count
 */
- (NSUInteger)getCountFromTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return 0;
    }
    NSString *sql = [NSString stringWithFormat:COUNT_ALL_SQL, tableName];
    __block NSInteger num = 0;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        if ([rs next]) {
//            num = [rs unsignedLongLongIntForColumn:@"num"];
            num = [rs intForColumn:@"num"];
        }
        [rs close];
    }];
    return num;
}

/**
 根据key值删除表中某个数据
 */
- (void)deleteObjectByKey:(NSString *)objectKey fromTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return;
    }
    NSString *sql = [NSString stringWithFormat:DELETE_ITEM_SQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql, objectKey];
    }];
    if (!result) {
        debugLog(@"ERROR, failed to delete item from table: %@", tableName);
    }
}

/**
 删除表中包含key值数组的数据
 */
- (void)deleteObjectsByKeyArray:(NSArray *)objectKeyArray fromTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return;
    }
    NSMutableString *stringBuilder = [NSMutableString string];
    for (id objectKey in objectKeyArray) {
        NSString *item = [NSString stringWithFormat:@" '%@' ", objectKey];
        if (stringBuilder.length == 0) {
            [stringBuilder appendString:item];
        } else {
            [stringBuilder appendString:@","];
            [stringBuilder appendString:item];
        }
    }
    NSString *sql = [NSString stringWithFormat:DELETE_ITEMS_SQL, tableName, stringBuilder];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    if (!result) {
        debugLog(@"ERROR, failed to delete items by keys from table: %@", tableName);
    }
}

/**
 删除表中以key为前缀的数据
 */
- (void)deleteObjectsByKeyPrefix:(NSString *)objectKeyPrefix fromTable:(NSString *)tableName {
    if ([WFDatabase checkTableName:tableName] == NO) {
        return;
    }
    NSString *sql = [NSString stringWithFormat:DELETE_ITEMS_WITH_PREFIX_SQL, tableName];
//  static NSString *const DELETE_ITEMS_WITH_PREFIX_SQL = @"DELETE from %@ where key like ? ";
    
    NSString *prefixArgument = [NSString stringWithFormat:@"%@%%", objectKeyPrefix];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql, prefixArgument];
    }];
    if (!result) {
        debugLog(@"ERROR, failed to delete items by id prefix from table: %@", tableName);
    }
}

/**
 关闭数据库
 */
- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}

@end
