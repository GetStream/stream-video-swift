//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class RecordingController {
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    private let callId: String
    private let callType: String
    
    var onRecordingEvent: ((RecordingEvent) -> Void)?
    var onRecordingRequestedEvent: ((RecordingEvent) -> Void)?
        
    private var coordinatorClient: CoordinatorClient {
        callCoordinatorController.coordinatorClient
    }
    
    init(
        callCoordinatorController: CallCoordinatorController,
        currentUser: User,
        callId: String,
        callType: String
    ) {
        self.callCoordinatorController = callCoordinatorController
        self.currentUser = currentUser
        self.callId = callId
        self.callType = callType
    }
    
    /// Starts recording a call with the specified call ID and call type.
    /// - Parameters:
    ///   - callId: The ID of the call to start recording.
    ///   - callType: The type of the call to start recording.
    /// - Throws: An error if the recording fails.
    func startRecording(callId: String, callType: String) async throws {
        let callCid = callCid(from: callId, callType: callType)
        let recordingEvent = RecordingEvent(callCid: callCid, type: callType, action: .requested)
        try await coordinatorClient.startRecording(callId: callId, callType: callType)
        onRecordingRequestedEvent?(recordingEvent)
    }
    
    /// Stops recording a call with the specified call ID and call type.
    /// - Parameters:
    ///   - callId: The ID of the call to stop recording.
    ///   - callType: The type of the call to stop recording.
    /// - Throws: An error if stopping the recording fails.
    func stopRecording(callId: String, callType: String) async throws {
        try await coordinatorClient.stopRecording(callId: callId, callType: callType)
    }
    
    /// Lists recordings for a call with the specified call ID, call type, and session.
    /// - Parameters:
    ///   - callId: The ID of the call to list recordings for.
    ///   - callType: The type of the call to list recordings for.
    ///   - session: The session to list recordings for.
    /// - Returns: An array of `CallRecordingInfo` objects representing the recordings for the specified call.
    func listRecordings(
        callId: String,
        callType: String,
        session: String
    ) async throws -> [CallRecordingInfo] {
        let recordingsResponse = try await coordinatorClient.listRecordings(
            callId: callId,
            callType: callType,
            session: session
        )
        let recordings = recordingsResponse.recordings.map(\.toRecordingInfo)
        return recordings
    }
    
    /// Creates an asynchronous stream of `RecordingEvent` objects.
    /// - Returns: An `AsyncStream` of `RecordingEvent` objects.
    func recordingEvents() -> AsyncStream<RecordingEvent> {
        let callCid = callCid(from: callId, callType: callType)
        let events = AsyncStream(RecordingEvent.self) { [weak self] continuation in
            self?.onRecordingEvent = { event in
                if event.callCid == callCid {
                    continuation.yield(event)
                }
            }
        }
        return events
    }
    
    func cleanUp() {
        onRecordingEvent = nil
        onRecordingRequestedEvent = nil
    }
}

public struct RecordingEvent {
    public let callCid: String
    public let type: String
    public let action: RecordingEventAction
}

public enum RecordingEventAction {
    case requested
    case started
    case stopped
}

extension RecordingEventAction {
    var toState: RecordingState {
        switch self {
        case .requested:
            return .requested
        case .started:
            return .recording
        case .stopped:
            return .noRecording
        }
    }
}

public struct CallRecordingInfo {
    public let startTime: Date
    public let endTime: Date
    public let filename: String
    public let url: String
}

extension CallRecording {
    var toRecordingInfo: CallRecordingInfo {
        CallRecordingInfo(
            startTime: startTime,
            endTime: endTime,
            filename: filename,
            url: url
        )
    }
}
