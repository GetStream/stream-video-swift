//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct PrivacySettings: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var readReceipts: ReadReceipts? = nil
    public var typingIndicators: TypingIndicators? = nil

    public init(readReceipts: ReadReceipts? = nil, typingIndicators: TypingIndicators? = nil) {
        self.readReceipts = readReceipts
        self.typingIndicators = typingIndicators
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case readReceipts = "read_receipts"
        case typingIndicators = "typing_indicators"
    }
}
