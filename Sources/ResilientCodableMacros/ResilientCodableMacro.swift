import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


enum ResilientCodableDiagnostic: String, DiagnosticMessage {
    case illegalDecl
    case noTypeAnnotationProvided
    
    var message: String {
        switch self {
            case .illegalDecl:
                return "'@ResilientCodable' can only be applied to a 'struct' or a 'class'."
            case .noTypeAnnotationProvided:
                return "An explicit type must be provided."
        }
    }
    
    var diagnosticID: SwiftDiagnostics.MessageID {
        MessageID(domain: "ResilientCodableMacros", id: rawValue)
    }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity { return .error }
    
    
}

public struct ResilientCodableMacro: MemberMacro, ExtensionMacro {
    
    private static func writeDecodeBlocks(for variables: [(String, String)]) -> String {
        var output = ""
        for (name, type) in variables {
            output.append(
            """
            
            do {
                if let \(name) = try container.decodeIfPresent(\(type).self, forKey: .\(name)) {
                    self.\(name) = \(name)
                }
            } catch {}
            """)
        }
        return output
    }
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            // TODO: Add FixIt
            let wrongDeclError = Diagnostic(node: node, message: ResilientCodableDiagnostic.illegalDecl)
            context.diagnose(wrongDeclError)
            return []
        }
        
        var variables: [(String, String)] = []
        for member in declaration.memberBlock.members {
            let decl = member.decl
            if let varDecl = decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let _ = binding.initializer {
                        if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                            guard let typeAnnotation = binding.typeAnnotation else {
                                // TODO: Add FixIt
                                let noTypeError = Diagnostic(node: varDecl, message: ResilientCodableDiagnostic.noTypeAnnotationProvided)
                                context.diagnose(noTypeError)
                                return []
                            }
                            let name = identifier.description
                            let type = typeAnnotation.type.trimmed.description
                            variables.append((name, type))
                        }
                        // TODO: Add other patterns (e.g. tuples)
                    }
                }
            }
        }
        
        let decodeBlocks = writeDecodeBlocks(for: variables)
        return [
            """
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(raw: decodeBlocks)
            }
            """
        ]
    }
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard !protocols.contains(where: {$0.description == "Codable"}) else {
            return []
        }
        let output = try ExtensionDeclSyntax(
            """
            extension \(raw: type): Codable {}
            """
        )
        return [output]
    }
}

@main
struct ResilientCodablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ResilientCodableMacro.self
    ]
}
