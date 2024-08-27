//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct AudioSettingsRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public enum DefaultDevice: String, Codable, CaseIterable {
        case earpiece
        case speaker
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
    
    public var accessRequestEnabled: Bool? = nil
    public var defaultDevice: DefaultDevice
    public var micDefaultOn: Bool? = nil
    public var noiseCancellation: NoiseCancellationSettings? = nil
    public var opusDtxEnabled: Bool? = nil
    public var redundantCodingEnabled: Bool? = nil
    public var speakerDefaultOn: Bool? = nil

    public init(
        accessRequestEnabled: Bool? = nil,
        defaultDevice: DefaultDevice,
        micDefaultOn: Bool? = nil,
        noiseCancellation: NoiseCancellationSettings? = nil,
        opusDtxEnabled: Bool? = nil,
        redundantCodingEnabled: Bool? = nil,
        speakerDefaultOn: Bool? = nil
    ) {
        self.accessRequestEnabled = accessRequestEnabled
        self.defaultDevice = defaultDevice
        self.micDefaultOn = micDefaultOn
        self.noiseCancellation = noiseCancellation
        self.opusDtxEnabled = opusDtxEnabled
        self.redundantCodingEnabled = redundantCodingEnabled
        self.speakerDefaultOn = speakerDefaultOn
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessRequestEnabled = "access_request_enabled"
        case defaultDevice = "default_device"
        case micDefaultOn = "mic_default_on"
        case noiseCancellation = "noise_cancellation"
        case opusDtxEnabled = "opus_dtx_enabled"
        case redundantCodingEnabled = "redundant_coding_enabled"
        case speakerDefaultOn = "speaker_default_on"
    }
}
