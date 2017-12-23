## 简介

这是一个基于FMDB封装的轻量级数据库，可直接存储自定义对象（对象模型里可嵌套对象）、字典数组或是其他OC类型数据。个性化修改一些接口，并在唐巧的[YTKKeyValueStore](https://github.com/yuantiku/YTKKeyValueStore) 基础上引入对象序列化存储。序列化库使用的是[FastCoding](https://github.com/nicklockwood/FastCoding)

## 使用

#### 极简的存取方法

```
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
```

## 示例：

```
//    初始化数据库，创建test表（默认数据库位于document/database.sqlite）
    WxfDatabase *database = [WxfDatabase shareDatabase];
    NSString *test_table = @"test";
    [database createTableWithName:test_table];
    
//    存取 NSString、NSNumber类型
    [database putObject:@"hellokitty" withKey:@"hello_kitty" intoTable:test_table];
    [database putObject:@666 withKey:@"666" intoTable:test_table];
    NSString *string = [database getObjectByKey:@"hello_kitty" fromTable:test_table];
    NSNumber *num = [database getObjectByKey:@"666" fromTable:test_table];
    
    NSLog(@"string(%@): %@, num(%@): %@",NSStringFromClass(string.class),string, NSStringFromClass(num.class),num);
    
//    存取字典
    NSDictionary *dict = @{@"id": @1, @"name": @"tangqiao", @"age": @30};
    [database putObject:dict withKey:@"dict" intoTable:test_table];
    NSDictionary *dict2 = [database getObjectByKey:@"dict" fromTable:test_table];
    NSLog(@"dict2: %@",dict2);

//    存取数组
    NSArray *arr = @[@"123",@"array",@99,@{@"key":@"value"},[NSNumber numberWithBool:YES]];
    [database putObject:arr withKey:@"arr" intoTable:test_table];
    NSArray *arr2 = [database getObjectByKey:@"arr" fromTable:test_table];
    NSLog(@"arr2: %@",arr2);
    
//    新建student表
    NSString *stu_table = @"student";
    [database createTableWithName:stu_table];
    
//    student对象
    MJStudent *stu = [self create_student];
    NSLog(@"stu: %@",stu);
    
//    存取自定义对象，对象模型内可嵌套对象（将对象序列化，存储数据库）
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
    NSLog(@"原先对象数据stu.ID=%@",stu.ID);
    stu.ID = @"12345";
    [database putObject:stu withKey:@"stu" intoTable:stu_table];
    MJStudent *stu12345 = [database getObjectByKey:@"stu" fromTable:stu_table];
    NSLog(@"修改后对象数据stu.ID=%@",stu12345.ID);
    
//    删除key为stu4的元素
    [database deleteObjectByKey:@"stu4" fromTable:stu_table];
    
//    删除数组中所有包含的key的元素
    [database deleteObjectsByKeyArray:@[@"stu5",@"stu6"] fromTable:stu_table];
    
//    删除key值前缀为stu的元素
    [database deleteObjectsByKeyPrefix:@"stu" fromTable:stu_table];
    
//    删除表
    [database dropTable:stu_table];
    
    
//    缓存大量数据时，可直接存储对象数组
    NSMutableArray *modleArr = [NSMutableArray array];
    for (int i = 0; i < 1000; i++) {
        MJStudent *stu = [self create_student];
        stu.ID = [NSString stringWithFormat:@"%4d",i];
        stu.age = i;
        stu.gay = YES;
        [modleArr addObject:stu];
    }
    [database putObject:modleArr withKey:@"modleArr" intoTable:test_table];
    NSArray *modleArr2 = [database getObjectByKey:@"modleArr" fromTable:test_table];
//    NSLog(@"modleArr2: %@",modleArr2);

    for (int i = 0; i < 1000; i++) {
        if (i > 10 && i < 990) {
            continue;
        }
        MJStudent *stu = modleArr2[i];
        NSLog(@"stu: %@",stu);
    }
    
    
//    一个student测试对象
- (MJStudent *)create_student {
    
    MJBag *bag = [[MJBag alloc] init];
    bag.name = @"小书包";
    bag.price = 998;
    
//    初始化student模型，里面装了一个bag模型
    MJStudent *stu = [[MJStudent alloc] init];
    stu.ID = @"123";
    stu.age = 24;
    stu.gay = NO;
    stu.name = @"izual";
    stu.createDate = [NSDate date];
    stu.books = @[@"Good book", @"Red book"];
    stu.bag = bag;
    
    return stu;
}
```

> ps: 对象序列化使用 `FastCoder`，需设置`-fno-objc-arc` 非ARC环境

