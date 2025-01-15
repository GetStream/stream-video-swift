//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension String {
    /// Returns a new unique string
    static var unique: String { UUID().uuidString }
}

public extension Int {
    static var unique: Int { .random(in: 1..<1000) }
}
