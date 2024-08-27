//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct StartRecordingRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var recordingExternalStorage: String? = nil

    public init(recordingExternalStorage: String? = nil) {
        self.recordingExternalStorage = recordingExternalStorage
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case recordingExternalStorage = "recording_external_storage"
    }
}
