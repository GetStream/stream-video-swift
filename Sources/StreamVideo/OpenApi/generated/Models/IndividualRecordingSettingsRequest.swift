//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IndividualRecordingSettingsRequest: Sendable, Encodable, JSONEncodable {
    
    public enum IndividualRecordingSettingsRequestMode: String, Sendable, Codable, CaseIterable {
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

    /// Recording mode. One of: available, disabled, auto-on
    public let mode: IndividualRecordingSettingsRequestMode
    /// Output types to include: audio_only, video_only, audio_video, screenshare_audio_only, screenshare_video_only, screenshare_audio_video
    public let outputTypes: [String]?

    public init(mode: IndividualRecordingSettingsRequestMode, outputTypes: [String]? = nil) {
        self.mode = mode
        self.outputTypes = outputTypes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(outputTypes, forKey: .outputTypes)
    }
}

extension IndividualRecordingSettingsRequest: Hashable {
    public static func == (lhs: IndividualRecordingSettingsRequest, rhs: IndividualRecordingSettingsRequest) -> Bool {
        lhs.mode == rhs.mode &&
            lhs.outputTypes == rhs.outputTypes
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
        hasher.combine(outputTypes)
    }
}
