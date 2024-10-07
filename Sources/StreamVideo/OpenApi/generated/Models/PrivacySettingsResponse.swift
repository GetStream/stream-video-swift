//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class PrivacySettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var readReceipts: ReadReceiptsResponse?
    public var typingIndicators: TypingIndicatorsResponse?

    public init(readReceipts: ReadReceiptsResponse? = nil, typingIndicators: TypingIndicatorsResponse? = nil) {
        self.readReceipts = readReceipts
        self.typingIndicators = typingIndicators
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case readReceipts = "read_receipts"
        case typingIndicators = "typing_indicators"
    }
    
    public static func == (lhs: PrivacySettingsResponse, rhs: PrivacySettingsResponse) -> Bool {
        lhs.readReceipts == rhs.readReceipts &&
            lhs.typingIndicators == rhs.typingIndicators
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(readReceipts)
        hasher.combine(typingIndicators)
    }
}
