//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

#if swift(>=6.0)
extension String: @retroactive CodingKey {
    public var stringValue: String { self }
    public init?(stringValue: String) { self.init(stringLiteral: stringValue) }
    public var intValue: Int? { nil }
    public init?(intValue: Int) { nil }
}
#else
extension String: CodingKey {
    public var stringValue: String { self }
    public init?(stringValue: String) { self.init(stringLiteral: stringValue) }
    public var intValue: Int? { nil }
    public init?(intValue: Int) { nil }
}
#endif
