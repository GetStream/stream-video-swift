//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

extension FunctionDeclSyntax {
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
    func removeTrivia() -> FunctionDeclSyntax {
        var node = self
        node.leadingTrivia = Trivia(pieces: cleanTrivia(node.leadingTrivia))
        node.trailingTrivia = Trivia(pieces: cleanTrivia(node.trailingTrivia))
        return node
    }
    
    func removeBody() -> FunctionDeclSyntax {
        var node = self
        node.body = nil
        return node
    }
    
    func definition(depth: Int) -> String {
        let result = description
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return String(repeating: "\t", count: depth) + result
    }
}
