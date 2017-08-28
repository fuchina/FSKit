//
//  FSDBMaster.h
//  Demo
//
//  Created by fudon on 2017/5/16.
//  Copyright © 2017年 fuhope. All rights reserved.
//

/*
 1.给表添加字段:   @"ALTER TABLE `erlingyiqi` ADD `deflag` TEXT NULL;"
 NSString *value = nil;
 if (!value) {
 NSString *sql = [[NSString alloc] initWithFormat:@"ALTER TABLE `%@` ADD `deflag` TEXT NULL;",_accountName];
 
 FSDBMaster *m = [FSDBMaster sharedInstance];
 NSString *error = [m execSQL:sql type:nil];
 if (error) {
 NSLog(@"%@",error);
 }
 return;
 }
 
 2.
 
 */

/*
 NOTE:
 1.需要在 Link Binary With Libraries 中导入 libsqlite3.tbd库
 2.因为id是苹果的关键字，所以用aid来作为自增id名，Model里有这个名为aid属性，就会得到NSNumber的值；但不能给这个属性赋值。
 3.表名,不要和所存的类名相同。因为如果类增加了字段，表中就没有该字段。
 4.time是唯一key，如果time相同，会报错。如果time是[[NSDate date] timeSecondSince1970]的秒数，有小数点后数字的话，一般都不相同
 5.多线程会出错，比如在 dispatch_group_t dispatchGroup = dispatch_group_create();中多线程查询，会出现EXC_BAD_ACCESS
 6.貌似FMDB也是串行队列
 7.数据类型有
 NULL，值是NULL
 INTEGER，值是有符号整形，根据值的大小以1,2,3,4,6或8字节存放
 REAL，值是浮点型值，以8字节IEEE浮点数存放
 TEXT，值是文本字符串，使用数据库编码（UTF-8，UTF-16BE或者UTF-16LE）存放
 BLOB，只是一个数据块，完全按照输入存放（即没有准换）
 。。。。。。
 
 */

#import <Foundation/Foundation.h>
#import "FSKit.h"

#define FSDBMaster_DBName       @"FSDBMasterDB"

@interface FSDBMaster : NSObject

/*
 错误处理回调
 */
@property (nonatomic,copy) void (^errorBlock)(NSInteger bType,NSString *bDescription);

/*
 打开默认的数据库
 */
+ (FSDBMaster *)sharedInstance;

/*
 打开的是传入的dbName数据
 */
+ (FSDBMaster *)sharedInstanceWithDBName:(NSString *)dbName;

// 根据数据库名字获取本地路径
-(NSString *)dbPath;

/*
 新增 eg.
 @"INSERT INTO %@ (time,name,loti,lati) VALUES (\"%@\",\"%@\",\"%@\",\"%@\");";
 */
- (NSString *)insertSQL:(NSString *)sql class:(Class)instance tableName:(NSString *)tableName;
/*
 删除  eg
 @"DELETE FROM %@ WHERE time = '%@';"
 注意time的值，time是字符串，所以要用''来表示，如果time是字符型数字时加不加''都没关系，但如果time是155555.8888之类时，因为那个小数点导致必须加上''才能找到time
 */
- (NSString *)deleteSQL:(NSString *)sql;
/*
 更新  eg.
 @"UPDATE %@ SET lati = '%@',loti = '%@' WHERE time = '%@';"
 */
- (NSString *)updateWithSQL:(NSString *)sql;

- (NSString *)execSQL:(NSString *)SQL type:(NSString *)type;

/*
 【SELECT DISTINCT name FROM %@;】// 从%@表中查询name字段的所有不重复的值
 【SELECT * FROM %@ WHERE name = 'ddd';】
 【SELECT * FROM %@ order by time DESC limit 0,10;】    ASC
 【SELECT * FROM %@ WHERE atype = ? OR btype = ? and time BETWEEN 1483228800 AND 1514764799 order by time DESC limit 0,10;】
 */
- (NSMutableArray *)querySQL:(NSString *)sql tableName:(NSString *)tableName;

//  检查表是否存在
- (BOOL)checkTableExist:(NSString *)tableName;

//  获取表名的所有数据数量
- (int)countForTable:(NSString *)tableName;

/*
 根据sql语句获取满足条件的数据数量；count(*)内部可以是*，也可是字段名来限制范围。
 【select count(*) from dbgroup Where cast(freq as INTEGER) > 30;】查询满足条件的数据条数；
 【select count(DISTINCT type) from dbgroup;】查询type不同种类，比如type有password和diary两种，就返回2;
 */
- (int)countWithSQL:(NSString *)sql table:(NSString *)table;

// 获取数据库中所有表名
- (NSArray<NSString *> *)allTables;

/*
 所有关键字，不能用作表名或字段名
 */
- (NSArray<NSString *> *)keywords;

@end



