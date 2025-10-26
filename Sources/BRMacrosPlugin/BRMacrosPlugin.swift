//
//  BRMacrosPlugin.swift
//  BRMacrosPlugin
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


@main
struct BRMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        LogMacro.self,
    ]
}


// MARK: - LogMacro


/// Log Macro 實作
/// 根據編譯時的最低部署目標，自動選擇 Logger 或 Print 實作
public struct LogMacro: ExpressionMacro {
    
    
    enum MacroError: Error, CustomStringConvertible {
        case wrongNumberOfArguments
        case invalidCategory
        case invalidLevel
        
        var description: String {
            switch self {
            case .wrongNumberOfArguments:
                return "#Log macro requires 3 arguments: (category, level, message)"
            case .invalidCategory:
                return "Category must be a member of BRLogCategory (.ui, .core, .network, .io, .library, .test)"
            case .invalidLevel:
                return "Level must be a member of BRLogLevel (.debug, .info, .notice, .error, .fault)"
            }
        }
    }
    
    
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext) throws -> ExprSyntax {
        // 解析參數
        guard node.arguments.count == 3 else {
            throw MacroError.wrongNumberOfArguments
        }
        
        let arguments = Array(node.arguments)
        
        let category = try getCategory(arguments[0])
        let level = try getLevel(arguments[1])
        let osLevel = level.replacingOccurrences(of: "notice", with: "default")
        let message = arguments[2].expression

        let expandedCode = """
        {
            if #available(iOS 14, macOS 11, watchOS 7, tvOS 14, *) {
                let logInfo = BRLogInfo(category: .\(category), level: .\(level), items: [\(message)], file: #file, function: #function, line: #line)
                let log = BRLog.format(logInfo)
                os_log(.\(osLevel), log: BRLogCategory.\(category).osLog, \"\\(log)\")
                BRLog.onOutput?(logInfo)
            } else {
                let logInfo = BRLogInfo(category: .\(category), level: .\(level), items: [\(message)], file: #file, function: #function, line: #line)
                let log = BRLog.format(logInfo)
                os_log(.\(osLevel), log: BRLogCategory.\(category).osLog, "%{public}@", \"\\(log)\")
                BRLog.onOutput?(logInfo)
            }
        }()
        """
        
        return "\(raw: expandedCode)"
    }
    
    
    /// 將 category enum 值轉換為 BRLog 的屬性名稱
    private static func getCategory(_ argument: LabeledExprListSyntax.Element) throws -> String {
        guard let categoryExprSyntax = argument.expression.as(MemberAccessExprSyntax.self) else {
            throw MacroError.invalidCategory
        }
        let category = categoryExprSyntax.declName.baseName.text
        return category.lowercased()
    }
    
    
    private static func getLevel(_ argument: LabeledExprListSyntax.Element) throws -> String {
        guard let levelExprSyntax = argument.expression.as(MemberAccessExprSyntax.self) else {
            throw MacroError.invalidCategory
        }
        let levelName = levelExprSyntax.declName.baseName.text
        return levelName
    }
    
    
}
