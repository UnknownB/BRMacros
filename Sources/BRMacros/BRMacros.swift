// The Swift Programming Language
// https://docs.swift.org/swift-book

@freestanding(expression)
public macro BRLog(_ category: BRLogCategory, _ level: BRLogLevel, _ message: String) = #externalMacro(module: "BRMacrosPlugin", type: "LogMacro")
