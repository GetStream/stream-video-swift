//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

struct ContainerCustomStringConvertible: CustomStringConvertible {

    var node: ContainerDeclSyntax?
    var depth: Int
    var members: [PublicInterfaceEntry]

    private var definition: String {
        if let node {
            let attributes = node
                .attributes
                .map { Syntax($0).stripLeadingOrTrailingComments().description }

            let modifiers = node
                .modifiers
                .map(\.name.text.description)

            let inheritanceClause = {
                guard let value = node.inheritanceClause else {
                    return ""
                }
                var result = value
                    .inheritedTypes
                    .map(\.type.description)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .joined(separator: ", ")

                if !result.isEmpty {
                    result = ": \(result)"
                }

                return result
            }()

            let result = [
                attributes,
                modifiers,
                [node.typeAsString()],
                [node.nameString],
                [inheritanceClause]
            ]
            .flatMap { $0 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

            return (depth == 0 ? "\n\n" : "") + String(repeating: "\t", count: depth) + result
        } else {
            return (depth == 0 ? "\n\n" : "") + String(repeating: "\t", count: depth) + "Global"
        }
    }

    private var membersDescription: String {
        var result: [String] = []

        for member in members {
            switch member {
            case let .container(node, depth, members):
                let description = ContainerCustomStringConvertible(
                    node: node,
                    depth: depth,
                    members: members
                ).description

                result.append(description)

            case let .variable(node, depth):
                result.append(node.definition(depth: depth))

            case let .enumCase(node, depth):
                result.append(node.definition(depth: depth))

            case let .function(node, depth):
                result.append(node.definition(depth: depth))

            case let .subscript(node, depth):
                return node.definition(depth: depth)

            case let .initialiser(node, depth):
                result.append(node.definition(depth: depth))
            }
        }

        return result.joined(separator: "\n")
    }

    var description: String {
        [definition, membersDescription].joined(separator: "\n")
    }
}
