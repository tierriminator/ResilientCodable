import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ResilientCodableMacros)
import ResilientCodableMacros

let testMacros: [String: Macro.Type] = [
    "ResilientCodable": ResilientCodableMacro.self
]
#endif

final class ResilientCodableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(ResilientCodableMacros)
        assertMacroExpansion(
            """
            @ResilientCodable
            struct Test {
                var foo: Int = 0
            }
            """,
            expandedSource: """
            struct Test {
                var foo: Int = 0
            
                init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
            
                    do {
                        if let foo = try container.decodeIfPresent(Int.self, forKey: .foo) {
                            self.foo = foo
                        }
                    } catch {
                    }
                }
            }
            
            extension Test: Codable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
