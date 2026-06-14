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
    
    
    public struct MaskingRule {
        public let pattern: String
        public let replacement: String
        let regex: NSRegularExpression
        
        public init(regex: NSRegularExpression, replacement: String = "****") {
            self.regex = regex
            self.pattern = regex.pattern
            self.replacement = replacement
        }
        
        public init(pattern: String, replacement: String = "****") {
            self.pattern = pattern
            self.replacement = replacement
            do {
                self.regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            } catch {
                assertionFailure("BRLogInfo.MaskingRule 錯誤的正規表示法: \(pattern)")
                self.regex = try! NSRegularExpression(pattern: "a^", options: [])
            }
        }
    }
    
    
    public init(category: BRLogCategory, level: BRLogLevel, items: [Any], file: String, function: String, line: Int) {
        self.category = category
        self.level = level
        self.message = BRLogInfo.mask(items)
        self.file = file
        self.fileName = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
        self.function = function
        self.line = line
        self.timestamp = BRLog.iso8601Formatter.string(from: Date())
    }
    
    
    private static func mask(_ items: [Any]) -> String {
        let message = items.map { "\($0)" }.joined(separator: ", ")
        
        guard !BRLog.maskingRules.isEmpty else {
            return message
        }
        
        var mutatedMessage = message
        for rule in BRLog.maskingRules {
            let range = NSRange(mutatedMessage.startIndex..<mutatedMessage.endIndex, in: mutatedMessage)
            mutatedMessage = rule.regex.stringByReplacingMatches(in: mutatedMessage, options: [], range: range, withTemplate: rule.replacement)
        }
        return mutatedMessage
    }
}
