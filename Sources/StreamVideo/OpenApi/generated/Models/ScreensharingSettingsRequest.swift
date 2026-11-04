//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class ScreensharingSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var accessRequestEnabled: Bool?
    public var enabled: Bool?
    public var targetResolution: TargetResolution?

    public init(accessRequestEnabled: Bool? = nil, enabled: Bool? = nil, targetResolution: TargetResolution? = nil) {
        self.accessRequestEnabled = accessRequestEnabled
        self.enabled = enabled
        self.targetResolution = targetResolution
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.accessRequestEnabled = try container.decodeIfPresent(Bool.self, forKey: .accessRequestEnabled)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.targetResolution = try container.decodeIfPresent(TargetResolution.self, forKey: .targetResolution)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(accessRequestEnabled, forKey: .accessRequestEnabled)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(targetResolution, forKey: .targetResolution)
    }
}

extension ScreensharingSettingsRequest: Hashable {
    public static func == (lhs: ScreensharingSettingsRequest, rhs: ScreensharingSettingsRequest) -> Bool {
        lhs.accessRequestEnabled == rhs.accessRequestEnabled &&
            lhs.enabled == rhs.enabled &&
            lhs.targetResolution == rhs.targetResolution
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(accessRequestEnabled)
        hasher.combine(enabled)
        hasher.combine(targetResolution)
    }
}
