//
//  FSDBMaster.m
//  Demo
//
//  Created by fudon on 2017/5/16.
//  Copyright © 2017年 fuhope. All rights reserved.
//

#import "FSDBMaster.h"
#import <sqlite3.h>
#import <FSKit.h>

@interface FSDBMaster ()

@property (nonatomic,assign) sqlite3   *sqlite3;

@end

static NSString *_db_extension = @".sqlite";

static const char *_SQLManagerQueue = "FSDBMasterQueue";
@implementation FSDBMaster{
    dispatch_queue_t    _queue;
    NSString            *_dbName;
}

static FSDBMaster *_instance = nil;

+(FSDBMaster *)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[FSDBMaster alloc] init];
    });
    return _instance;
}

+ (FSDBMaster *)sharedInstanceWithDBName:(NSString *)dbName{
    FSDBMaster *master = [self sharedInstance];
    [master generateHandlerWithDBName:dbName];
    return master;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create(_SQLManagerQueue, DISPATCH_QUEUE_SERIAL);
        [self generateHandlerWithDBName:FSDBMaster_DBName];
    }
    return self;
}

- (void)generateHandlerWithDBName:(NSString *)dbName{
    if (!([dbName isKindOfClass:[NSString class]] && dbName.length)) {
        return;
    }
    
    NSString *currentDBPath = [self dbPath];
    NSString *currentDBName = [currentDBPath lastPathComponent];
    NSString *nowDBName = [[NSString alloc] initWithFormat:@"%@%@",dbName,_db_extension];
    if ([currentDBName isEqualToString:nowDBName]) {
        return;
    }
    
    NSString *dbPath = [self dbPathWithFileName:dbName];
    int openResult = sqlite3_open([dbPath UTF8String], &_sqlite3);
    if (openResult != SQLITE_OK) {
        sqlite3_close(_sqlite3);
        _sqlite3 = nil;
    }
}

- (NSString *)dbPath{// 数据库只能放在Documents目录下
    return [self dbPathWithFileName:_dbName];
}

// param: 不需要带扩展名
- (NSString *)dbPathWithFileName:(NSString *)name{
    if (!([name isKindOfClass:[NSString class]] && name.length)) {
        return nil;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *path = [docDir stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"%@%@",name,_db_extension]];
    
    _dbName = name;
    return path;
}

- (void)createTableIfNotExists:(NSString *)tableName className:(Class)className{
    if (![FSKit isValidateString:tableName]) {
        return;
    }
    BOOL exist = [self checkTableExistWithTableNamed:tableName];
    if (exist) {
        return;
    }
    NSArray *properties = [FSKit propertiesForClass:className];
    if (!properties.count) {
        return;
    }
    NSString *aid = @"aid";
    NSString *primaryKey = [[NSString alloc] initWithFormat:@"%@ integer PRIMARY KEY autoincrement,",aid];// 因为PRIMARY KEY，id自动是8个字节
    NSMutableString *append = [[NSMutableString alloc] initWithString:primaryKey];
    NSArray *keywords = [self keywords];
    for (int x = 0; x < properties.count; x ++) {
        NSString *name = properties[x];
        BOOL isKeyword = [keywords containsObject:name];
        if (isKeyword) {
            name = [[NSString alloc] initWithFormat:@"[%@]",name];
        }
        if ([name isEqualToString:aid]) {
            continue;
        }
        if (x == (properties.count - 1)){
            [append appendString:[[NSString alloc] initWithFormat:@"%@ TEXT NULL",name]];
        }else{
            [append appendString:[[NSString alloc] initWithFormat:@"%@ TEXT NULL,",name]];
        }
    }
    
    // PRIMARY KEY 是唯一的，每条数据不能相同
    //    NSString *sql = @"CREATE TABLE IF NOT EXISTS UserTable ( time TEXT NOT NULL PRIMARY KEY,atype TEXT NOT NULL,btype TEXT NOT NULL,je TEXT,bz TEXT,sr TEXT, cb TEXT, ys TEXT, xj TEXT, ch TEXT, tz TEXT, tx TEXT, fz TEXT);";
    NSString *sql = [[NSString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@);",tableName,append];
    [self execSQL:sql type:@"创建表"];
}

- (NSString *)insertSQL:(NSString *)sql class:(Class)instance tableName:(NSString *)tableName{
    if (![FSKit isValidateString:tableName]) {
        return @"表名为空";
    }
    [self createTableIfNotExists:tableName className:instance];
    return [self execSQL:sql type:@"新增数据"];
}

- (NSString *)deleteSQL:(NSString *)sql{
    return [self execSQL:sql type:@"删除数据"];
}

- (NSString *)updateWithSQL:(NSString *)sql{
    return [self execSQL:sql type:@"更新数据"];
}

- (NSString *)execSQL:(NSString *)SQL type:(NSString *)type{
    if (!([SQL isKindOfClass:[NSString class]] && SQL.length)) {
        return @"语句为空";
    }
    __block NSString *errMSG = nil;
    dispatch_sync(_queue, ^{
        char *error = NULL;
        int result = sqlite3_exec(_sqlite3, [SQL UTF8String], NULL, NULL, &error);
        if (result != SQLITE_OK) {
            errMSG = [[NSString alloc] initWithFormat:@"%@失败，原因:%s",type,error];
        }
    });
    return errMSG;
}

- (NSMutableArray *)querySQL:(NSString *)sql class:(Class)className tableName:(NSString *)tableName{
    return [self execQuerySQL:sql class:className tableName:tableName];
}

- (NSMutableArray *)execQuerySQL:(NSString *)sql class:(Class)className tableName:(NSString *)tableName{
    if (!([sql isKindOfClass:[NSString class]] && sql.length)) {
        return nil;
    }
    if (!className) {
        return nil;
    }
    if (!([tableName isKindOfClass:[NSString class]] && tableName.length)) {
        return nil;
    }
    BOOL exist = [self checkTableExistWithTableNamed:tableName];
    if (!exist) {
        return nil;
    }
    
    __block NSMutableArray *mArr = nil;
    dispatch_sync(_queue, ^{
        sqlite3_stmt *stmt = nil;
        int prepare = sqlite3_prepare_v2(_sqlite3, [sql UTF8String], -1, &stmt, NULL);
        if (prepare != SQLITE_OK) {
            sqlite3_finalize(stmt);
#if  DEBUG
            [FSKit showMessage:[[NSString alloc] initWithFormat:@"错误码:%@【DEBUG】",@(prepare)]];
#endif
            return;
        }
        
        mArr = [[NSMutableArray alloc] init];
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            id entity = [self entityWithStmt:stmt className:NSStringFromClass(className) tableName:tableName];
            if (entity) {
                [mArr addObject:entity];
            }
        }
        sqlite3_finalize(stmt);
    });
    if (mArr.count) {
        return mArr;
    }
    return nil;
}

- (int)countForTable:(NSString *)tableName{
    if (!([tableName isKindOfClass:[NSString class]] && tableName.length)) {
        return 0;
    }
    BOOL exist = [self checkTableExistWithTableNamed:tableName];
    if (!exist) {
        return 0;
    }
    
    __block int count = 0;
    dispatch_sync(_queue, ^{
        
        NSString *sql = [[NSString alloc] initWithFormat:@"SELECT COUNT(*) FROM %@;",tableName];
        sqlite3_stmt *stmt = nil;
        int prepare = sqlite3_prepare_v2(_sqlite3, [sql UTF8String], -1, &stmt, NULL);
        if (prepare != SQLITE_OK) {
#if DEBUG
            [FSKit showMessage:@"准备Stmt失败"];
#endif
            return;
        }
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            count += sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    });
    return count;
}

- (int)countWithSQL:(NSString *)sql table:(NSString *)tableName{
    if (!([tableName isKindOfClass:[NSString class]] && tableName.length)) {
        return 0;
    }
    BOOL exist = [self checkTableExistWithTableNamed:tableName];
    if (!exist) {
        return 0;
    }
    if (!([sql isKindOfClass:[NSString class]] && sql.length)) {
        return 0;
    }
    __block int count = 0;
    dispatch_sync(_queue, ^{
        sqlite3_stmt *stmt = nil;
        int prepare = sqlite3_prepare_v2(_sqlite3, [sql UTF8String], -1, &stmt, NULL);
        if (prepare != SQLITE_OK) {
#if DEBUG
            [FSKit showMessage:@"准备Stmt失败"];
#endif
            return;
        }
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            count += sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
    });
    return count;
}

- (BOOL)checkTableExist:(NSString *)tableName{
    if (!([tableName isKindOfClass:[NSString class]] && tableName.length)) {
        return NO;
    }
    __block BOOL success = NO;
    dispatch_sync(_queue, ^{
        sqlite3_stmt *statement;
        NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM sqlite_master where type='table' and name='%@';",tableName];
        const char *sql_stmt = [sql UTF8String];
        if (sqlite3_prepare_v2(_sqlite3, sql_stmt, -1, &statement, nil) == SQLITE_OK) {
            @try {
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    success = YES;
                    break;
                }
            } @catch (NSException *exception) {

            } @finally {
                sqlite3_finalize(statement);
            }
        }
    });
    return success;
}

- (BOOL)checkTableExistWithTableNamed:(NSString *)tableName{
    if (!([tableName isKindOfClass:[NSString class]] && tableName.length)) {
        return NO;
    }
    __block BOOL success = NO;
    dispatch_sync(_queue, ^{
        char *err;
        NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM sqlite_master where type='table' and name='%@';",tableName];
        const char *sql_stmt = [sql UTF8String];
        int result = sqlite3_exec(_sqlite3, sql_stmt, checkTableCallBack, (void *)[tableName UTF8String], &err);
        if(result != SQLITE_OK){
            return;
        }
        
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSString *exist = [ud objectForKey:tableName];
        success = exist.length?YES:NO;
    });
    return success;
}

/*
 int (*callback)(void*,int,char**,char**)
 * 函数参数:
 void *param 传递给callback回调函数的参数,对应于sqlite3_exec函数的第四个参数
 int f_num 查找到的记录中包含的字段数目
 char **f_value 包含查找到每个记录的字段值
 char **f_name 包含查找到每个记录的字段名称
 */

int checkTableCallBack(void *param, int f_num, char **f_value, char **f_name){
    NSString *p = [[NSString alloc] initWithUTF8String:param];// 传过来的参数
    NSInteger number = 0;
    if (f_num) {
        char *count = f_value[0];
        number = atoi(count);
    }
    
    if (number) {
        [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:p];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:p];
    }
    return 0;
}

- (id)entityWithStmt:(sqlite3_stmt *)stmt className:(NSString *)className tableName:(NSString *)tableName{
    if (className.length == 0) {
        return nil;
    }
    Class Entity = NSClassFromString(className);
    id ps = [[Entity alloc] init];
    NSArray *fields = [self allFields:tableName];
    for (int x = 0; x < fields.count; x ++) {
        NSDictionary *dic = fields[x];
        NSString *name = [dic objectForKey:_field_name];
        SEL setterSelector = [FSKit setterSELWithAttibuteName:name];
        if ([ps respondsToSelector:setterSelector]) {
            const char *charValue = (const char*)sqlite3_column_text(stmt, x);
            NSString *type = [dic objectForKey:_field_type];
            id value = nil;
            if ([type isEqualToString:@"integer"]){
                NSString *str = [[NSString alloc] initWithUTF8String:charValue];
                value = @([str integerValue]);
            }else{
                value = [[NSString alloc] initWithUTF8String:charValue];
            }
            [ps performSelector:setterSelector onThread:[NSThread currentThread] withObject:value waitUntilDone:YES];
        }
    }
    return ps;
}

static NSString     *_field_name = @"field_name";
static NSString     *_field_type = @"field_type";
//获取表中所有字段名和类型
-(NSArray<NSDictionary *> *)allFields:(NSString *)tableName{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSString *getColumn = [NSString stringWithFormat:@"PRAGMA table_info(%@)",tableName];
    sqlite3_stmt *statement;
    sqlite3_prepare_v2(_sqlite3, [getColumn UTF8String], -1, &statement, nil);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char *nameData = (char *)sqlite3_column_text(statement, 1);
        NSString *columnName = [[NSString alloc] initWithUTF8String:nameData];
        char *typeData = (char *)sqlite3_column_text(statement, 2);
        NSString *columntype = [NSString stringWithCString:typeData encoding:NSUTF8StringEncoding];
        NSDictionary *dic = @{_field_name:columnName,_field_type:[columntype lowercaseString]};
        [array addObject:dic];
    }
    sqlite3_finalize(statement);
    statement = nil;
    return array;
}

- (NSArray<NSString *> *)allTables{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    const char *getTableInfo = "select * from sqlite_master where type='table' order by name";
    if (sqlite3_prepare_v2(_sqlite3, getTableInfo, -1, &statement, nil) == SQLITE_OK) {
        @try {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                char *nameData = (char *)sqlite3_column_text(statement, 1);
                NSString *tableName = [[NSString alloc] initWithUTF8String:nameData];
                [array addObject:tableName];
            }
        } @catch (NSException *exception) {
            return nil;
        } @finally {
            sqlite3_finalize(statement);
            return array.count?array:nil;
        }
    }
}

- (NSArray<NSString *> *)keywords{
    static NSArray *list = nil;
    if (!list) {
        list = @[@"select",@"insert",@"update",@"delete",@"from",@"creat",@"where",@"desc",@"order",@"by",@"group",@"table",@"alter",@"view",@"index"];
    }
    return list;
}

@end
