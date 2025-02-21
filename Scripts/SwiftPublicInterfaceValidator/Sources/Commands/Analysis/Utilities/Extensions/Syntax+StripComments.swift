//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

extension Syntax {
    func stripLeadingOrTrailingComments() -> Syntax {
        var node = self
        let filteredLeadingTrivia = node.leadingTrivia.filter { piece in
            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                return false // Remove comment trivia
            default:
                return true // Keep other trivia (like spaces, newlines)
            }
        }

        let filteredTrailingTrivia = node.trailingTrivia.filter { piece in
            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                return false // Remove comment trivia
            default:
                return true // Keep other trivia (like spaces, newlines)
            }
        }

        node.leadingTrivia = Trivia(pieces: filteredLeadingTrivia)
        node.trailingTrivia = Trivia(pieces: filteredTrailingTrivia)

        return node
    }
}
