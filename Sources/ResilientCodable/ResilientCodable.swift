// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(init(from:)))
public macro ResilientCodable() = #externalMacro(module: "ResilientCodableMacros", type: "ResilientCodableMacro")
