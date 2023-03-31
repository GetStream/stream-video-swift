//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class CallController_Mock: CallController {
    
    let mockResponseBuilder = MockResponseBuilder()
    
    override func joinCall(
        callType: CallType,
        callId: String,
        callSettings: CallSettings,
        videoOptions: VideoOptions,
        participants: [User],
        ring: Bool = false
    ) async throws -> Call {
        let callSettingsInfo = makeCallSettingsInfo(
            callId: callId,
            callType: callType
        )
        return Call.create(
            callId: callId,
            callType: callType,
            sessionId: UUID().uuidString,
            callSettingsInfo: callSettingsInfo,
            recordingState: .noRecording
        )
    }
    
    override func changeAudioState(isEnabled: Bool) async throws { /* no op */ }
    
    override func changeVideoState(isEnabled: Bool) async throws { /* no op */ }
    
    override func changeCameraMode(position: CameraPosition, completion: @escaping () -> ()) {
        completion()
    }
    
    override func selectEdgeServer(
        videoOptions: VideoOptions,
        participants: [User]
    ) async throws -> EdgeServer {
        EdgeServer(
            url: "localhost",
            token: "token",
            iceServers: [],
            callSettings: makeCallSettingsInfo(callId: "test", callType: .default),
            latencyURL: nil
        )
    }
    
    // MARK: - private
    
    func makeCallSettingsInfo(callId: String, callType: CallType) -> CallSettingsInfo {
        let callSettingsInfo = CallSettingsInfo(
            callCapabilities: [],
            callSettings: mockResponseBuilder.makeCallSettingsResponse(),
            callInfo: CallInfo(
                cId: "\(callType.name):\(callId)",
                backstage: false,
                blockedUsers: []
            ),
            recording: false
        )
        return callSettingsInfo
    }
    
}
