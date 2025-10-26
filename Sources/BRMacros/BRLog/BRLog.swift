//
//  BRLog.swift
//
//
//  Created by BR on 2024/10/24.
//

import Foundation
import OSLog

/// BRLog - 用於記錄日誌，提供控制台輸出與日誌管理
///
/// ## 基本使用
///
/// ```
/// do {
///     ...
/// } catch {
///     #BRLog(.network, .error, "[API] error: \(error)") // ❌ [Network] FileName・Line -- [API] error: error...
/// }
/// ```
///
/// ## 額外功能
///
/// - 格式化
///     - 使用 #BRLog 會取得檔案名稱、行數等資訊印出
///     - 透過 BRLog.onFormat 自訂格式
/// - 事件捕捉
///     - 使用 #BRLog 會保留跳轉功能，並且觸發 callback
///     - 透過 BRLog.onOutput 自訂動作
/// - 日誌管理
///     - 使用 BRLog.writeLogToStore 將日誌記錄
///     - 使用 BRLog.logFiles 取得所有日誌路徑
///     - 使用 BRLog.readLog 讀取日誌內容
///
///
public enum BRLog {
    
    
    // MARK: - Store

    
    /// Log 檔案最大保留數量，預設 5
    public static var maxLogFileCount: Int {
        get { BRLogStore.maxLogFileCount }
        set { BRLogStore.maxLogFileCount = newValue }
    }
    
    
    /// 單一 Log 檔案大小上限（bytes），預設 1MB
    public static var maxSingleFileSize: Int64 {
        get { BRLogStore.maxSingleFileSize }
        set { BRLogStore.maxSingleFileSize = newValue }
    }
    
    
    /// 關閉目前的 Log 檔案，再次紀錄 Log 時，將清空檔案重新開始
    public static func closeCuttentLogFile() {
        BRLogStore.closeCuttentLogFile()
    }
    
    
    /// 寫入自訂的儲存檔案，會依第一次呼叫時間建立儲存檔案，若數量超過 `maxLogFileCount` 將刪除最舊的紀錄
    public static func writeLogToStore(_ message: String) {
        BRLogStore.writeLogToStore(message)
    }
    
    
    /// 列出所有 log 檔案路徑（由新到舊排序）
    public static func logFiles() -> [URL] {
        BRLogStore.logFiles()
    }
    
    
    /// 讀取日誌尾端訊息，預設為 64KB
    public static func readTailLog(from url: URL, maxBytes: Int = 64 * 1024) -> String {
        BRLogStore.readTailLog(from: url, maxBytes: maxBytes)
    }
    
    
    /// 讀取日誌尾端訊息，預設為 64KB
    public static func readTailLog(from index: Int, maxBytes: Int = 64 * 1024) -> String {
        BRLogStore.readTailLog(from: index, maxBytes: maxBytes)
    }
    
    
    /// 讀取日誌完整訊息，以串流方式分次傳入
    public static func readLogStream(from url: URL, lineHandler: (String) -> Void) {
        BRLogStore.readLogStream(from: url, lineHandler: lineHandler)
    }
    
    
    /// 讀取日誌完整訊息，以串流方式分次傳入
    public static func readLogStream(from index: Int, lineHandler: (String) -> Void) {
        BRLogStore.readLogStream(from: index, lineHandler: lineHandler)
    }
    
    
    // MARK: - Format
    
    
    /// 自訂 Log 顯示訊息
    nonisolated(unsafe) public static var onFormat: ((BRLogInfo) -> String)? = nil
    
    
    nonisolated(unsafe) public static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        formatter.formatOptions = [
            .withInternetDateTime
        ]
        return formatter
    }()

    
    public static func format(_ logInfo: BRLogInfo) -> String {
        if let onFormat = onFormat {
            return onFormat(logInfo)
        }
        return "\(logInfo.level.emoji) [\(logInfo.category.rawValue)] \(logInfo.fileName)・\(logInfo.line) -- \(logInfo.message)"
    }

    
    // MARK: - Hook
    
    
    /// 透過 #BRLog 印出訊息時，將自動 callback 此 closure
    nonisolated(unsafe) public static var onOutput: ((BRLogInfo) -> Void)? = nil
    
    
}


// MARK: - Print


extension BRLog {
    public static let printUI = BRLogCategory.ui.printLog
    public static let printIO = BRLogCategory.io.printLog
    public static let printCore = BRLogCategory.core.printLog
    public static let printTest = BRLogCategory.test.printLog
    public static let printNet = BRLogCategory.network.printLog
    public static let printLib = BRLogCategory.library.printLog
}


// MARK: - Logger


@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension BRLog {
        
    public static let ui = BRLogCategory.ui.logger
    public static let io = BRLogCategory.io.logger
    public static let lib = BRLogCategory.library.logger
    public static let net = BRLogCategory.network.logger
    public static let core = BRLogCategory.core.logger
    public static let test = BRLogCategory.test.logger
    
    
    /// 取得目前 Process 內的 OSLog 紀錄
    /// - Throws: 若 OSLogStore 無法存取，則拋出錯誤
    /// - Returns: `OSLogEntryLog` 陣列
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public static func fetchOSLogStore() throws -> [OSLogEntryLog] {
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        let predicate = NSPredicate(format: "subsystem == %@", BRLogCategory.subsystem)
        
        let entries = try logStore.getEntries(matching: predicate)
        let logs = entries.compactMap { $0 as? OSLogEntryLog } // 轉換成 OSLogEntryLog 獲得更多屬性
        return logs
    }
    
    
}


// MARK: Description


@available(macOS 10.15, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension OSLogEntryLog {
    
    
    public override var description: String {
        let symbol = BRLogLevel.fromOSLogLevel(level).emoji
        return "\(symbol) [\(self.category)] -- \(self.composedMessage)"
    }
    
    
}
