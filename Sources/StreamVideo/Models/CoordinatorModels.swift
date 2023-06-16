//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallSettingsResponse: @unchecked Sendable {}
extension ModelResponse: @unchecked Sendable {}
extension AcceptCallResponse: @unchecked Sendable {}
extension RejectCallResponse: @unchecked Sendable {}
extension CallResponse: @unchecked Sendable {}
extension OwnCapability: @unchecked Sendable {}

public struct FetchingLocationError: Error {}

public enum RecordingState {
    case noRecording
    case requested
    case recording
}
