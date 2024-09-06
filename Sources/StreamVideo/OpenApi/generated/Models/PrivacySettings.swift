//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct PrivacySettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var readReceipts: ReadReceipts?
    public var typingIndicators: TypingIndicators?

    public init(readReceipts: ReadReceipts? = nil, typingIndicators: TypingIndicators? = nil) {
        self.readReceipts = readReceipts
        self.typingIndicators = typingIndicators
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case readReceipts = "read_receipts"
        case typingIndicators = "typing_indicators"
    }
}
