//
//  BRLogLevel.swift
//  BRMacros
//
//  Created by BR on 2025/10/25.
//

import Foundation
import OSLog


public enum BRLogLevel: String, CaseIterable {
    /// 用於 Debug 模式
    case debug = "Debug"
    /// 用於系統的狀態變化
    case info = "Info"
    /// 用於操作成功
    case notice = "Notice"
    /// 用於操作失敗
    case error = "Error"
    /// 用於 crash 級別嚴重錯誤
    case fault = "Fault"
    
    public var emoji: String {
        switch self {
        case .debug: "🛠️"
        case .info: "⚙️"
        case .notice: "☑️"
        case .error: "❌"
        case .fault: "⚠️"
        }
    }
    
    @available(macOS 10.15, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public static func fromOSLogLevel(_ level: OSLogEntryLog.Level) -> Self {
        switch level {
        case .debug: .debug
        case .info: .info
        case .notice: .notice
        case .error: .error
        case .fault: .fault
        default: .debug
        }
    }
}
