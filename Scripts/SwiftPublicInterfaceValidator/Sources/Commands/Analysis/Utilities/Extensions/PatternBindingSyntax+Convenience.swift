//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

extension PatternBindingSyntax {
    /// Removes the accessor block (e.g., get/set) from the PatternBindingSyntax
    func removingAccessorBlock() -> PatternBindingSyntax {
        var node = self
        node.accessorBlock = nil
        return node
    }

    /// Removes the accessor block (e.g., get/set) from the PatternBindingSyntax
    func removingInitializer() -> PatternBindingSyntax {
        var node = self
        node.initializer = nil
        return node
    }

    func removingComments() -> PatternBindingSyntax {
        // Helper to clean trivia by removing comments
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

        // Clean leading and trailing trivia of each token in the PatternBindingSyntax
        var node = self
        node.leadingTrivia = Trivia(pieces: cleanTrivia(leadingTrivia))
        node.trailingTrivia = Trivia(pieces: cleanTrivia(trailingTrivia))

        node.pattern.leadingTrivia = Trivia(pieces: cleanTrivia(node.pattern.leadingTrivia))
        node.pattern.trailingTrivia = Trivia(pieces: cleanTrivia(node.pattern.trailingTrivia))

        node.pattern.leadingTrivia = Trivia(pieces: cleanTrivia(node.pattern.leadingTrivia))
        node.pattern.trailingTrivia = Trivia(pieces: cleanTrivia(node.pattern.trailingTrivia))

        if var typeAnnotation = node.typeAnnotation {
            typeAnnotation.leadingTrivia = Trivia(pieces: cleanTrivia(typeAnnotation.leadingTrivia))
            typeAnnotation.trailingTrivia = Trivia(pieces: cleanTrivia(typeAnnotation.trailingTrivia))
            node.typeAnnotation = typeAnnotation
        }

        if var initializer = node.initializer {
            initializer.leadingTrivia = Trivia(pieces: cleanTrivia(initializer.leadingTrivia))
            initializer.trailingTrivia = Trivia(pieces: cleanTrivia(initializer.trailingTrivia))
            node.initializer = initializer
        }

        if var accessor = node.accessorBlock {
            accessor.leadingTrivia = Trivia(pieces: cleanTrivia(accessor.leadingTrivia))
            accessor.trailingTrivia = Trivia(pieces: cleanTrivia(accessor.trailingTrivia))
            node.accessorBlock = accessor
        }

        return node
    }
}
