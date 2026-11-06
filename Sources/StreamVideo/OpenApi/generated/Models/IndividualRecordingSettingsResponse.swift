//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IndividualRecordingSettingsResponse: @unchecked Sendable, Decodable {
    
    public enum IndividualRecordingSettingsResponseMode: String, Sendable, Codable, CaseIterable {
        case autoOn = "auto-on"
        case available
        case disabled
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    public var mode: IndividualRecordingSettingsResponseMode
    public var outputTypes: [String]?

    public init(mode: IndividualRecordingSettingsResponseMode, outputTypes: [String]? = nil) {
        self.mode = mode
        self.outputTypes = outputTypes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mode = try container.decode(IndividualRecordingSettingsResponseMode.self, forKey: .mode)
        self.outputTypes = try container.decodeIfPresent([String].self, forKey: .outputTypes)
    }
}

extension IndividualRecordingSettingsResponse: Hashable {
    public static func == (lhs: IndividualRecordingSettingsResponse, rhs: IndividualRecordingSettingsResponse) -> Bool {
        lhs.mode == rhs.mode &&
            lhs.outputTypes == rhs.outputTypes
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
        hasher.combine(outputTypes)
    }
}
