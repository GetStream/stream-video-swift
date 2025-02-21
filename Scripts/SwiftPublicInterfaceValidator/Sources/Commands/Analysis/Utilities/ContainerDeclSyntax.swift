//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

protocol ContainerDeclSyntax {
    var attributes: AttributeListSyntax { get }
    var nameString: String { get }
    var memberBlock: MemberBlockSyntax { get }
    var modifiers: DeclModifierListSyntax { get }
    var inheritanceClause: InheritanceClauseSyntax? { get }

    func root() -> DeclSyntaxProtocol
    func typeAsString() -> String
}

extension ContainerDeclSyntax {
    func root() -> DeclSyntaxProtocol { self as! DeclSyntaxProtocol }
}

extension ClassDeclSyntax: ContainerDeclSyntax {
    var nameString: String { name.text }
    func typeAsString() -> String { "class" }
}

extension StructDeclSyntax: ContainerDeclSyntax {
    var nameString: String { name.text }
    func typeAsString() -> String { "struct" }
}

extension EnumDeclSyntax: ContainerDeclSyntax {
    var nameString: String { name.text }
    func typeAsString() -> String { "enum" }
}

extension ActorDeclSyntax: ContainerDeclSyntax {
    var nameString: String { name.text }
    func typeAsString() -> String { "actor" }
}

extension ProtocolDeclSyntax: ContainerDeclSyntax {
    var nameString: String { name.text }
    func typeAsString() -> String { "protocol" }
}

extension ExtensionDeclSyntax: ContainerDeclSyntax {
    var nameString: String { extendedType.description }

    func typeAsString() -> String { "extension" }
}
