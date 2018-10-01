//
//  MJStudent.m
//  MJExtensionExample
//
//  Created by MJ Lee on 15/1/5.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "MJStudent.h"

@implementation MJStudent

- (NSString *)description {
    return [NSString stringWithFormat:@"ID: %@, name: %@, age: %ld, createDate: %@, bag: %@, books: %@",_ID,_name,(long)_age,_createDate,_bag,_books];
}

@end
