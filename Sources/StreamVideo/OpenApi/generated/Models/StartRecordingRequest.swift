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

    public enum CodingKeys: String, CodingKey {
        case recordingExternalStorage = "recording_external_storage"
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
