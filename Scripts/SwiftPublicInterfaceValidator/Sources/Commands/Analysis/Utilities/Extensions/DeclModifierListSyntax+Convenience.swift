//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftSyntax

extension DeclModifierListSyntax {
    var isPublicOrOpen: Bool {
        contains([.public, .open])
    }

    func contains(
        _ values: [Keyword]
    ) -> Bool {
        var found: [Bool] = []
        values.forEach { value in
            found.append(self.first { $0.name.tokenKind == .keyword(value) } != nil)
        }
        let result = found.contains { $0 == true }
        return result
    }
}
