//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

enum PublicInterfaceEntry: CustomStringConvertible {
    case container(ContainerDeclSyntax?, Int, [PublicInterfaceEntry])
    case variable(VariableDeclSyntax, Int)
    case enumCase(EnumCaseDeclSyntax, Int)
    case function(FunctionDeclSyntax, Int)
    case `subscript`(SubscriptDeclSyntax, Int)
    case initialiser(InitializerDeclSyntax, Int)

    var description: String {
        switch self {
        case let .container(node, depth, members):
            return ContainerCustomStringConvertible(
                node: node,
                depth: depth,
                members: members
            ).description

        case let .variable(node, depth):
            return node.definition(depth: depth)

        case let .enumCase(node, depth):
            return node.definition(depth: depth)

        case let .function(node, depth):
            return node.definition(depth: depth)

        case let .subscript(node, depth):
            return node.definition(depth: depth)

        case let .initialiser(node, depth):
            return node.definition(depth: depth)
        }
    }
}
