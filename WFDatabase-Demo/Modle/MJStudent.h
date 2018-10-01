//
//  MJStudent.h
//  MJExtensionExample
//
//  Created by MJ Lee on 15/1/5.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MJBag;

@interface MJStudent : NSObject

@property (nonatomic,copy ) NSString *ID;
@property (nonatomic,copy,) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign, getter=isGay) BOOL gay;
@property (nonatomic, strong)NSDate *createDate;
@property (nonatomic,strong) MJBag *bag;
@property (nonatomic,strong) NSArray *books;

@end
