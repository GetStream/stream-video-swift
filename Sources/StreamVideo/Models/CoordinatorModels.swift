//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct EdgeServer: Sendable {
    let url: String
    let webSocketURL: String
    let token: String
    let iceServers: [IceServer]
    let callSettings: CallSettingsInfo
    let latencyURL: String?
}

struct CallSettingsInfo: Sendable {
    let callCapabilities: [String]
    let callSettings: CallSettingsResponse
    let state: CallData
    let recording: Bool
}

extension CallSettingsResponse: @unchecked Sendable {}
extension ModelResponse: @unchecked Sendable {}

struct IceServer: Sendable {
    let urls: [String]
    let username: String
    let password: String
}

struct CoordinatorInfo {
    let apiKey: String
    let hostname: String
    let token: String
}

public struct FetchingLocationError: Error {}

public enum RecordingState {
    case noRecording
    case requested
    case recording
}
