//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StartRecordingRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var recordingExternalStorage: String?

    public init(recordingExternalStorage: String? = nil) {
        self.recordingExternalStorage = recordingExternalStorage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.recordingExternalStorage = try container.decodeIfPresent(String.self, forKey: .recordingExternalStorage)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(recordingExternalStorage, forKey: .recordingExternalStorage)
    }
}

extension StartRecordingRequest: Hashable {
    public static func == (lhs: StartRecordingRequest, rhs: StartRecordingRequest) -> Bool {
        lhs.recordingExternalStorage == rhs.recordingExternalStorage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(recordingExternalStorage)
    }
}
