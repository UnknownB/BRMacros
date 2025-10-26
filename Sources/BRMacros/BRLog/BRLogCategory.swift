//
//  BRLogCategory.swift
//  BRMacros
//
//  Created by BR on 2025/10/25.
//

import Foundation
import OSLog


/// 自定義 Log 類型，可依需求進行擴充，預設提供 UI、IO、Core、Test、Network、Library
public struct BRLogCategory: Hashable, Equatable, RawRepresentable, ExpressibleByStringLiteral, Sendable {
    public static let subsystem = Bundle.main.bundleIdentifier!
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
            
    public static func custom(for token: String) -> BRLogCategory {
        return BRLogCategory(rawValue: token)
    }
    
    public var printLog: PrintLog {
        PrintLog(tag: self)
    }
    
    public var osLog: OSLog {
        OSLog(subsystem: Self.subsystem, category: rawValue)
    }
    
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    public var logger: Logger {
        Logger(subsystem: Self.subsystem, category: rawValue)
    }
    
    /// UI 操作
    public static let ui: BRLogCategory = "UI"
    /// 檔案存取
    public static let io: BRLogCategory = "IO"
    /// 邏輯運算
    public static let core: BRLogCategory = "Core"
    /// 功能測試
    public static let test: BRLogCategory = "Test"
    /// 網路操作
    public static let network: BRLogCategory = "Network"
    /// 第三方庫
    public static let library: BRLogCategory = "Library"
}


extension BRLogCategory {
    
    public struct PrintLog : Sendable {
        
        let tag: BRLogCategory
        
        public func debug(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
            let log = BRLog.format(BRLogInfo(category: tag, level: .debug, items: items, file: file, function: function, line: line))
            #if DEBUG
            print(log)
            #endif
        }
        
        public func info(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
            let log = BRLog.format(BRLogInfo(category: tag, level: .info, items: items, file: file, function: function, line: line))
            print(log)
        }

        public func notice(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
            let log = BRLog.format(BRLogInfo(category: tag, level: .notice, items: items, file: file, function: function, line: line))
            print(log)
        }
        
        public func error(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
            let log = BRLog.format(BRLogInfo(category: tag, level: .error, items: items, file: file, function: function, line: line))
            print(log)
        }
        
        public func fault(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
            let log = BRLog.format(BRLogInfo(category: tag, level: .fault, items: items, file: file, function: function, line: line))
            print(log)
        }
    }

}

