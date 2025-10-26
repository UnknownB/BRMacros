//
//  BRLogStore.swift
//  BRMacros
//
//  Created by BR on 2025/10/25.
//

import Foundation
import OSLog

public enum BRLogStore {
    
    /// Log 檔案最大保留數量
    nonisolated(unsafe) public static var maxLogFileCount: Int = 5
    
    /// 單一 Log 檔案大小上限（bytes）
    nonisolated(unsafe) public static var maxSingleFileSize: Int64 = 1 * 1024 * 1024
    

    nonisolated(unsafe) private static var logHandle : FileHandle?
    nonisolated(unsafe) private static var hasLoggingError = false
    private static let lockQueue = DispatchQueue(label: "com.br.BRLog.Store", attributes: .concurrent)
    
    
    /// Log 檔案存放路徑
    private static let logsDirectory: URL = {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let dir = library.appendingPathComponent("BRLogs", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()
    
    
    /// 當前 Log 檔案路徑
    private static let logFile: URL = {
        let fileName = BRLog.iso8601Formatter.string(from: Date()) + ".log"
        return logsDirectory.appendingPathComponent(fileName)
    }()
    
    
    // MARK: - Create
    
    
    /// 在首次寫入 log 時自動建立 FileHandle
    private static func createFileHandle() -> FileHandle? {
        do {
            FileManager.default.createFile(atPath: logFile.path, contents: nil, attributes: nil)
            return try FileHandle(forWritingTo: logFile)
        } catch {
            #BRLog(.library, .error, "[BRLog] 無法建立日誌檔案: \(error)")
            hasLoggingError = true
            return nil
        }
    }
    
    
    // MARK: - Close
    
    
    /// 關閉目前的 Log 檔案，再次紀錄 Log 時，將清空檔案重新開始
    public static func closeCuttentLogFile() {
        lockQueue.async(flags: .barrier) {
            logHandle?.closeFile()
            logHandle = nil
        }
    }
    
    
    // MARK: - Write
    
    
    /// 寫入自訂的儲存檔案，會依第一次呼叫時間建立儲存檔案，若數量超過 `maxLogFileCount` 將刪除最舊的紀錄
    public static func writeLogToStore(_ message: String) {
        lockQueue.async(flags: .barrier) {
            
            // 檢查檔案大小是否超過上限
            if let size = try? FileManager.default.attributesOfItem(atPath: logFile.path)[.size] as? Int64, size >= maxSingleFileSize {
                closeCuttentLogFile()
                let tailLogs = Self.readTailLog(from: 0)
                writeLogToStore(tailLogs)
            }
            
            if logHandle == nil {
                if hasLoggingError {
                    return
                }
                logHandle = createFileHandle()
                trimLogFilesIfNeeded()
            }
            
            guard let logHandle = logHandle else {
                return
            }
            
            let data = "\(message)\n".data(using: .utf8)!
            logHandle.seekToEndOfFile()
            logHandle.write(data)
        }
    }
    
    
    // MARK: - Read
    

    /// 列出所有 log 檔案路徑（由新到舊排序）
    public static func logFiles() -> [URL] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: logsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }
        
        return files.sorted { lhs, rhs in
            let lDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lDate > rDate
        }
    }
    
    
    /// 讀取日誌尾端訊息，預設為 64KB
    public static func readTailLog(from url: URL, maxBytes: Int = 64 * 1024) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return ""
        }
        defer {
            try? handle.close()
        }
        
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        let offset = max(0, fileSize - Int64(maxBytes))
        
        try? handle.seek(toOffset: UInt64(offset))
        guard let data = try? handle.readDataToEndOfFile() else {
            return ""
        }
        
        guard var text = String(data: data, encoding: .utf8) else {
            return ""
        }
        
        // 若有截斷情況，移除第一行不完整內容
        if offset > 0, let firstLineBreak = text.firstIndex(of: "\n") {
            text = String(text[text.index(after: firstLineBreak)...])
        }
        
        return text
    }
    
    
    /// 讀取日誌尾端訊息，預設為 64KB
    public static func readTailLog(from index: Int, maxBytes: Int = 64 * 1024) -> String {
        let files = logFiles()
        guard index < files.count else {
            return ""
        }
        return readTailLog(from: files[index], maxBytes: maxBytes)
    }
    
    
    /// 讀取日誌完整訊息，以串流方式分次傳入
    public static func readLogStream(from url: URL, lineHandler: (String) -> Void) {
        guard let stream = InputStream(url: url) else {
            return
        }
        defer {
            stream.close()
        }
        stream.open()

        let bufferSize = 8 * 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var leftover = Data()
        
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read > 0 {
                leftover.append(contentsOf: buffer[..<read])
                while let range = leftover.firstRange(of: Data([0x0A])) { // newline
                    let lineData = leftover[..<range.lowerBound]
                    leftover.removeSubrange(...range.lowerBound)
                    if let line = String(data: lineData, encoding: .utf8) {
                        lineHandler(line)
                    }
                }
            } else { break }
        }
        
        if !leftover.isEmpty, let last = String(data: leftover, encoding: .utf8) {
            lineHandler(last)
        }
    }
    
    
    /// 讀取日誌完整訊息，以串流方式分次傳入
    public static func readLogStream(from index: Int, lineHandler: (String) -> Void) {
        let files = logFiles()
        guard index < files.count else {
            return
        }
        return readLogStream(from: files[index], lineHandler: lineHandler)
    }

    
        
    // MARK: - Remove
    
    
    /// 當檔案數量超過限制，從最舊的資料開始刪除
    private static func trimLogFilesIfNeeded() {
        let files = logFiles()
        guard files.count > maxLogFileCount else { return }
        
        let excess = files.dropFirst(maxLogFileCount)
        for file in excess {
            try? FileManager.default.removeItem(at: file)
        }
    }
    

}
