//
//  BRLogInfo.swift
//  BRMacros
//
//  Created by BR on 2025/10/25.
//

import Foundation


/// 封裝 Log 構成資訊
public struct BRLogInfo {
    public let category: BRLogCategory
    public let level: BRLogLevel
    public let message: String
    public let file: String
    public let fileName: String
    public let function: String
    public let line: Int
    public let timestamp: String
    
    public init(category: BRLogCategory, level: BRLogLevel, items: [Any], file: String, function: String, line: Int) {
        self.category = category
        self.level = level
        self.message = items.map { "\($0)" }.joined(separator: ", ")
        self.file = file
        self.fileName = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
        self.function = function
        self.line = line
        self.timestamp = BRLog.iso8601Formatter.string(from: Date())
    }
}
