//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

extension VariableDeclSyntax {
    func cleanTrivia(_ trivia: Trivia?) -> Trivia {
        Trivia(pieces: trivia?.compactMap { piece in
            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                return nil // Remove comment pieces
            default:
                return piece // Keep other trivia like spaces, newlines
            }
        } ?? [])
    }

    /// Removes the accessor block (e.g., get/set) from the PatternBindingSyntax
    func removingInitializer() -> VariableDeclSyntax {
        var node = self
        var newBindings = [PatternBindingSyntax]()
        node.bindings.forEach {
            newBindings.append(
                $0
                    .removingInitializer()
                    .removingAccessorBlock()
                    .removingComments()
            )
        }
        node.bindings = .init(newBindings)
        node.bindingSpecifier.leadingTrivia = Trivia(pieces: cleanTrivia(node.bindingSpecifier.leadingTrivia))
        node.bindingSpecifier.trailingTrivia = Trivia(pieces: cleanTrivia(node.bindingSpecifier.trailingTrivia))
        return node
    }

    func definition(depth: Int) -> String {
        let attributes = self
            .attributes
            .map { Syntax($0).stripLeadingOrTrailingComments().description }
        let modifiers = self
            .modifiers
            .map(\.name.text.description)
        let bindings = self
            .bindings
            .map { $0.removingAccessorBlock() }
            .map(\.description)

        let result = [
            attributes,
            modifiers,
            [bindingSpecifier.description],
            bindings
        ]
        .flatMap { $0 }
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " ")

        return String(repeating: "\t", count: depth) + result
    }
}
