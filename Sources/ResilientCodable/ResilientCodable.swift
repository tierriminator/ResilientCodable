// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(init(from:)))
@attached(extension, conformances: Codable)
public macro ResilientCodable() = #externalMacro(module: "ResilientCodableMacros", type: "ResilientCodableMacro")
