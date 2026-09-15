//
//  SwiftDBMaster.swift
//  ModuleOxfordUtils
//
//  Created by pwrd on 2026/1/26.
//  纯 Swift 版本的 FSDBMaster（SQLite 数据库封装）
//

import Foundation
import SQLite3

// MARK: - 类型别名
//typealias FSDBMaster = SwiftDBMaster

// MARK: - 主类
public class FSDBMaster {
    
    // MARK: - 属性
    private var sqlite3: OpaquePointer?
    private let queue: DispatchQueue
    
    // MARK: - 静态属性
    private static let dbExtension = ".db"
    private static let dbFirstName = "sql_ling"
    private static var defaultMaster: FSDBMaster?
    private static var currentMaster: FSDBMaster?
    private static let initQueue = DispatchQueue(label: "swiftdbmaster.sync")
    
    // MARK: - 初始化
    deinit {
        
        #if DEBUG
        print("SwiftDBMaster dealloc")
        #endif
        
        if let db = sqlite3 {
            sqlite3_close(db)
            sqlite3 = nil
        }
    }
    
    private init?(path: String) {
        guard !path.isEmpty else { return nil }
        
        self.queue = FSDBMaster.initQueue
        
        var success = false
        queue.sync {
            success = self.openSqlite3Database(at: path)
        }
        
        guard success else { return nil }
        
        #if DEBUG
        let mode = FSDBMaster.sqlite3Threadsafe()
        assert(mode == 2, "SQLite3线程模式不是2")
        #endif
    }
    
    // MARK: - 打开数据库
    @discardableResult
    private func openSqlite3Database(at path: String) -> Bool {
        guard !path.isEmpty else { return false }
        
        // 关闭已有连接
        if let db = sqlite3 {
            sqlite3_close(db)
            sqlite3 = nil
        }
        
        // 打开数据库
        let result = sqlite3_open(path, &sqlite3)
        if result != SQLITE_OK {
            if let db = sqlite3 {
                sqlite3_close(db)
                sqlite3 = nil
            }
            return false
        }
        
        // 设置同步模式
        sqlite3_exec(sqlite3, "PRAGMA synchronous=FULL;", nil, nil, nil)
        return true
    }
    
    // MARK: - 静态方法
    
    /// 打开指定路径的数据库
    static func openSQLite3(_ path: String?) -> FSDBMaster? {
        
        guard let path = path, !path.isEmpty else { return nil }
        
        // 初始化默认数据库
        if defaultMaster == nil {
            defaultMaster = FSDBMaster(path: dbPath())
        }
        
        // 如果是默认路径，返回默认实例
        if path == dbPath() {
            return defaultMaster
        }
        
        return FSDBMaster(path: path)
    }
    
    /// 获取共享实例（默认数据库）
    public static func sharedInstance2() -> FSDBMaster? {
        if currentMaster == nil {
            currentMaster = openSQLite3(dbPath())
        }
        return currentMaster
    }
    
    /// 获取共享实例（默认数据库）
    public static func sharedInstance() -> FSDBMaster {
        let m = self.sharedInstance2()
        if let m {
            return m
        }
        
        fatalError()
    }
        
    /// 默认数据库路径
    public static func dbPath() -> String {
        return dbPath(withFileName: dbFirstName)
    }
    
    /// 备份数据库文件路径（与当前数据库同级，用于上传快照）
    /// 上传前拷贝当前库到此路径，上传的是静态快照，不会因原库变化而失败
    public static func backups() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let docDir = paths.first else { return "" }
        
        return (docDir as NSString).appendingPathComponent("sql_ling_upload.db")
    }
    
    /// 根据文件名生成数据库路径
    static func dbPath(withFileName name: String) -> String {
        guard !name.isEmpty else { return "" }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let docDir = paths.first else { return "" }
        
        return (docDir as NSString).appendingPathComponent("\(name)\(dbExtension)")
    }
    
    /// 获取 SQLite 线程安全模式
    static func sqlite3Threadsafe() -> Int32 {
        return sqlite3_threadsafe()
    }
    
    // MARK: - 执行 SQL
    
    /// 执行 SQL 语句
    @discardableResult
    public func execSQL(_ sql: String?) -> String {
        guard let sql = sql, !sql.isEmpty else { return "SQL语句为空" }
        
        var errorMsg: String?
        queue.sync {
            var stmt: OpaquePointer?
            let result = sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil)
            
            if result == SQLITE_OK {
                let code = sqlite3_step(stmt)
                if code != SQLITE_DONE {
                    errorMsg = "错误码:\(code)"
                }
            } else {
                errorMsg = "错误码:\(result)"
            }
            
            sqlite3_finalize(stmt)
        }
        
        return errorMsg ?? ""
    }
    
    // MARK: - 插入
    
    /// 插入数据（使用 SQL 语句）
    @discardableResult
    func insertSQL(_ sql: String?) -> String? {
        return execSQL(sql)
    }
    
    /// 插入数据（使用字段-值字典）
    public func insert(fieldsValues: [String: Any]?, table: String?) -> String {
        guard let table = table, !table.isEmpty else {
            return "insertSQL: table name's length is zero"
        }
        
        guard let list = fieldsValues, !list.isEmpty else {
            return ""
        }
        
        let keys = Array(list.keys)
        
        // 检查表是否存在
        if !checkTableExist(table) {
            if let error = createTableIfNotExists(table, fields: keys), !error.isEmpty {
                return error
            }
        }
        
        var outErrorMsg: String = ""
        queue.sync {
            let fields = keys.joined(separator: ",")
            let placeholders = keys.map { ":\($0)" }.joined(separator: ",")
            let insertSQL = "INSERT INTO \(table) (\(fields)) VALUES (\(placeholders));"
            
            outErrorMsg = executeUpdate(insertSQL, fieldValues: list)
        }
        
        return outErrorMsg
    }
    
    // MARK: - 删除
    
    /// 删除数据（使用 SQL 语句）
    @discardableResult
    public func deleteSQL(_ sql: String?) -> String {
        return execSQL(sql)
    }
    
    /// 删除数据（根据 aid）
    @discardableResult
    public func deleteSQL(table: String?, aid: Int?) -> String {
        guard let table = table, !table.isEmpty, let aid = aid else {
            return "参数错误"
        }
        
        let sql = "DELETE FROM \(table) WHERE aid = \(aid);"
        return deleteSQL(sql)
    }
    
    // MARK: - 更新
    
    /// 更新数据（使用 SQL 语句）
    @discardableResult
    public func updateSQL(_ sql: String?) -> String {
        return execSQL(sql)
    }
    
    /// 更新数据（使用字段-值字典和条件）
    @discardableResult
    public func updateTable(_ table: String?, fieldsValues: [String: Any]?, where whereClause: String) -> String {
        guard let table = table, !table.isEmpty else { return "updateTable table 参数不对" }
        guard let fvs = fieldsValues, !fvs.isEmpty else { return "updateTable fvs 参数不对" }
        
        var outErrorMsg: String = ""
        queue.sync {
            let keys = Array(fvs.keys)
            var sqlParts: [String] = []
            
            for (index, key) in keys.enumerated() {
                if index == keys.count - 1 {
                    sqlParts.append("\(key) = :\(key)")
                } else {
                    sqlParts.append("\(key) = :\(key),")
                }
            }
            
            let sql = "UPDATE \(table) SET \(sqlParts.joined()) WHERE \(whereClause);"
            outErrorMsg = executeUpdate(sql, fieldValues: fvs)
        }
        
        return outErrorMsg
    }
    
    // MARK: - 查询
    
    /*
     【SELECT DISTINCT name FROM %@;】// 从%@表中查询name字段的所有不重复的值
     【SELECT * FROM %@ WHERE name = 'ddd';】
     【SELECT * FROM %@ order by time DESC limit 0,10;】    ASC
     【SELECT * FROM %@ WHERE atype = ? OR btype = ? and time BETWEEN 1483228800 AND 1514764799 order by time DESC limit 0,10;】
     */
    public func querySQL(_ sql: String?, tableName: String?) -> [[String: Any]] {
       
        guard let sql = sql, !sql.isEmpty else {
            return []
        }
        
        guard let tableName = tableName, !tableName.isEmpty else {
            return []
        }
        
        guard checkTableExist(tableName) else {
            return []
        }
        
        var results: [[String: Any]] = []
        queue.sync {
            var stmt: OpaquePointer?
            let prepare = sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil)
            
            guard prepare == SQLITE_OK else {
                sqlite3_finalize(stmt)
                return
            }
            
            var array: [[String: Any]] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let dict = dictionary(from: stmt) {
                    array.append(dict)
                }
            }
            
            sqlite3_finalize(stmt)
            
            results = array
        }
        
        return results
    }
    
    // MARK: - 表操作
    
    /// 检查表是否存在
    public func checkTableExist(_ tableName: String?) -> Bool {
        guard let tableName = tableName, !tableName.isEmpty else { return false }
        
        var exists = false
        queue.sync {
            var stmt: OpaquePointer?
            let sql = "SELECT COUNT(*) FROM sqlite_master where type='table' and name='\(tableName)';"
            
            if sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let count = sqlite3_column_int(stmt, 0)
                    if count > 0 {
                        exists = true
                        break
                    }
                }
            }
            
            sqlite3_finalize(stmt)
        }
        
        return exists
    }
    
    /// 创建表（如果不存在）
    @discardableResult
    private func createTableIfNotExists(_ tableName: String, fields: [String]) -> String? {
        guard !fields.isEmpty else { return "fields 为空" }
        guard !tableName.isEmpty else { return "表名为空" }
        
        if checkTableExist(tableName) {
            return nil
        }
        
        let keywords = self.keywords()
        let primaryKey = "aid INTEGER PRIMARY KEY autoincrement,"
        var fieldsParts: [String] = []
        
        for (index, field) in fields.enumerated() {
            guard !field.isEmpty else { continue }
            guard !keywords.contains(field) else { continue }
            guard field != "aid" else { continue }
            
            if index == fields.count - 1 {
                fieldsParts.append("\(field) TEXT NULL")
            } else {
                fieldsParts.append("\(field) TEXT NULL,")
            }
        }
        
        let sql = "CREATE TABLE IF NOT EXISTS \(tableName) (\(primaryKey)\(fieldsParts.joined()));"
        return execSQL(sql)
    }
    
    /// 删除表
    @discardableResult
    public func dropTable(_ table: String?) -> String {
        guard let table = table, !table.isEmpty else { return "表名为空" }
        
        let sql = "DROP TABLE IF EXISTS \(table);"
        return execSQL(sql)
    }
    
    /// 添加字段到表
    @discardableResult
    public func addField(_ field: String?, defaultValue: String?, toTable table: String?) -> String {
        guard let field = field, !field.isEmpty else { return "字段不是字符串" }
        guard let table = table, !table.isEmpty else { return "表名错误" }
        
        if keywords().contains(field) {
            return "字段名不能使用关键字"
        }
        
        guard checkTableExist(table) else { return "表不存在" }
        
        // 检查字段是否已存在
        if let fields = allFields(table) {
            for fieldDict in fields {
                if let name = fieldDict["field_name"] as? String, name == field {
                    return ""  // 字段已存在
                }
            }
        }
        
        let value = defaultValue ?? ""
        let sql = "ALTER TABLE '\(table)' ADD '\(field)' TEXT NULL DEFAULT '\(value)';"
        return execSQL(sql)
    }
    
    public func copyTable(_ table: String, toTable: String, quits: [String]) -> String {
        
        let sql = "SELECT * FROM \(table)"
        let list = self.querySQL(sql, tableName: table)
        if list.count == 0 {
            return ""
        }
        
        for var obj in list {
            obj.removeValue(forKey: "aid")
            
            for m in quits {
                obj.removeValue(forKey: m)
            }
                        
            let error = self.insert(fieldsValues: obj, table: toTable)
            if error.isEmpty == false {
                return error
            }
        }
        
        return ""
    }
    
    /// 获取所有表名
    public func allTables() -> [String]? {
        guard let details = allTablesDetail() else { return nil }
        
        return details.compactMap { $0["name"] as? String }
    }
    
    /// 获取所有表的详细信息
    func allTablesDetail() -> [[String: Any]]? {
        var results: [[String: Any]]?
        queue.sync {
            var stmt: OpaquePointer?
            let sql = "select * from sqlite_master where type = 'table' order by name"
            
            if sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil) == SQLITE_OK {
                var array: [[String: Any]] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let dict = dictionary(from: stmt) {
                        array.append(dict)
                    }
                }
                results = array.isEmpty ? nil : array
            }
            
            sqlite3_finalize(stmt)
        }
        
        return results
    }
    
    /// 获取表的所有字段
    public func allFields(_ tableName: String?) -> [[String: Any]]? {
        guard let tableName = tableName, !tableName.isEmpty else { return nil }
        
        var results: [[String: Any]]?
        queue.sync {
            var stmt: OpaquePointer?
            let sql = "PRAGMA table_info(\(tableName))"
            
            if sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil) == SQLITE_OK {
                var array: [[String: Any]] = []
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let nameData = sqlite3_column_text(stmt, 1),
                       let typeData = sqlite3_column_text(stmt, 2) {
                        let columnName = String(cString: nameData)
                        let columnType = String(cString: typeData).lowercased()
                        array.append([
                            "field_name": columnName,
                            "field_type": columnType
                        ])
                    }
                }
                results = array.isEmpty ? nil : array
            }
            
            sqlite3_finalize(stmt)
        }
        
        return results
    }
    
    // MARK: - 计数
    
    /// 获取表的数据数量
    public func count(forTable tableName: String?) -> Int {
        guard let tableName = tableName, !tableName.isEmpty else { return 0 }
        guard checkTableExist(tableName) else { return 0 }
        
        var count = 0
        queue.sync {
            var stmt: OpaquePointer?
            let sql = "SELECT COUNT(*) FROM \(tableName);"
            
            if sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    count += Int(sqlite3_column_int(stmt, 0))
                }
            }
            
            sqlite3_finalize(stmt)
        }
        
        return count
    }
    
    /// 根据 SQL 获取数据数量
    public func count(withSQL sql: String?, table: String?) -> Int {
        guard let sql = sql, !sql.isEmpty else { return 0 }
        guard let table = table, !table.isEmpty else { return 0 }
        guard checkTableExist(table) else { return 0 }
        
        var count = 0
        queue.sync {
            var stmt: OpaquePointer?
            
            if sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    count += Int(sqlite3_column_int(stmt, 0))
                }
            }
            
            sqlite3_finalize(stmt)
        }
        
        return count
    }
    
    // MARK: - 事务
    
    /// 事务处理
    /// - Parameter type: 1=开始事务, 2=提交事务, 3=回滚事务
    /// - Returns: 错误信息，nil 表示成功
    @discardableResult
    public func transactionHandler(_ type: Int) -> String {
        let sql: String
        switch type {
        case 1:
            sql = "begin;"
        case 2:
            sql = "commit;"
        case 3:
            sql = "ROLLBACK;"
        default:
            return "sql为NULL"
        }
        
        var errorMsg: UnsafeMutablePointer<Int8>?
        let result = sqlite3_exec(sqlite3, sql, nil, nil, &errorMsg)
        
        if result == SQLITE_OK {
            return ""
        }
        
        if let error = errorMsg {
            sqlite3_free(error)
        }
        
        return "事务操作失败，事务参数类型:\(type)"
    }
    
    // MARK: - 二进制存储
    
    /// 存储二进制数据
    @discardableResult
    func insertData(_ data: Data, table: String, key: String) -> String {
        guard !table.isEmpty else { return "表名为空" }
        guard !key.isEmpty else { return "key为空" }
        
        // 检查表是否存在
        if checkTableExist(table) {
            let sql = "select count(*) from \(table) where ky = '\(key)'"
            let count = self.count(withSQL: sql, table: table)
            if count > 0 {
                return "key值已存在"
            }
        } else {
            // 创建表
            let createTable = "CREATE TABLE IF NOT EXISTS \(table) (aid INTEGER PRIMARY KEY autoincrement,tm TEXT,ky TEXT,dt BLOB);"
            let error = execSQL(createTable)
            if !error.isEmpty {
                return error
            }
        }
        
        queue.sync {
            var stmt: OpaquePointer?
            let sql = "INSERT INTO \(table) (tm,ky,dt) VALUES (:tm,:ky,:dt)"
            
            if sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil) == SQLITE_OK {
                let tmIdx = sqlite3_bind_parameter_index(stmt, ":tm")
                let kyIdx = sqlite3_bind_parameter_index(stmt, ":ky")
                let dtIdx = sqlite3_bind_parameter_index(stmt, ":dt")
                
                let timestamp = String(Int(Date().timeIntervalSince1970))
                sqlite3_bind_text(stmt, tmIdx, timestamp, -1, nil)
                sqlite3_bind_text(stmt, kyIdx, key, -1, nil)
                
                _ = data.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(stmt, dtIdx, bytes.baseAddress, Int32(data.count), nil)
                }
                
                sqlite3_step(stmt)
            }
            
            sqlite3_finalize(stmt)
        }
        
        return ""
    }
    
    // MARK: - 辅助方法
    
    /// 执行更新操作（带参数绑定）
//    private func executeUpdate(_ sql: String, fieldValues: [String: Any]) -> String? {
//        var stmt: OpaquePointer?
//        
//        guard sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil) == SQLITE_OK else {
//            return "prepare failed"
//        }
//        
//        // 绑定参数
//        for (key, value) in fieldValues {
//            let paramName = ":\(key)"
//            let idx = sqlite3_bind_parameter_index(stmt, paramName)
//            
//            if idx > 0 {
//                let valueStr = "\(value)"
//                sqlite3_bind_text(stmt, idx, valueStr, -1, nil)
//            }
//        }
//        
//        let result = sqlite3_step(stmt)
//        sqlite3_finalize(stmt)
//        
//        if result != SQLITE_DONE {
//            return "executeUpdate failed (\(result)): \(sql)"
//        }
//        
//        return nil
//    }
    
    private func executeUpdate(_ sql: String, fieldValues: [String: Any]) -> String {
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(sqlite3, sql, -1, &stmt, nil) == SQLITE_OK else {
            return "prepare failed"
        }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        for (key, value) in fieldValues {
            let paramName = ":\(key)"
            let idx = sqlite3_bind_parameter_index(stmt, paramName)

            if idx > 0 {
                let valueStr = "\(value)"
                sqlite3_bind_text(stmt, idx, valueStr, -1, SQLITE_TRANSIENT)
            }
        }

        let result = sqlite3_step(stmt)
        sqlite3_finalize(stmt)

        if result != SQLITE_DONE {
            return "executeUpdate failed (\(result)): \(sql)"
        }

        return ""
    }
    
    /// 从 statement 中提取字典
    private func dictionary(from stmt: OpaquePointer?) -> [String: Any]? {
        guard let stmt = stmt else { return nil }
        
        var dict: [String: Any] = [:]
        let count = sqlite3_column_count(stmt)
        
        for i in 0..<count {
            guard let cname = sqlite3_column_name(stmt, i) else { continue }
            let name = String(cString: cname)
            
            let type = sqlite3_column_type(stmt, i)
            var value: Any = ""
            
            switch type {
            case SQLITE_TEXT:
                if let cValue = sqlite3_column_text(stmt, i) {
                    value = String(cString: cValue)
                }
                
            case SQLITE_BLOB, SQLITE_NULL:
                if let bytes = sqlite3_column_blob(stmt, i) {
                    let length = Int(sqlite3_column_bytes(stmt, i))
                    value = Data(bytes: bytes, count: length)
                }
                
            case SQLITE_INTEGER:
                value = Int(sqlite3_column_int(stmt, i))
                
            case SQLITE_FLOAT:
                value = Double(sqlite3_column_double(stmt, i))
                
            default:
                break
            }
            
            dict[name] = value
        }
        
        return dict
    }
    
    /// SQL 关键字列表
    public func keywords() -> [String] {
        return ["select", "insert", "update", "delete", "from", "creat", "where", "desc", "order", "by", "group", "table", "alter", "view", "index", "when", "on"]
    }
}
