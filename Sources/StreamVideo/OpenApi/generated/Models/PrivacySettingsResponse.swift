//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct PrivacySettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var readReceipts: ReadReceiptsResponse? = nil
    public var typingIndicators: TypingIndicatorsResponse? = nil

    public init(readReceipts: ReadReceiptsResponse? = nil, typingIndicators: TypingIndicatorsResponse? = nil) {
        self.readReceipts = readReceipts
        self.typingIndicators = typingIndicators
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case readReceipts = "read_receipts"
        case typingIndicators = "typing_indicators"
    }
}
