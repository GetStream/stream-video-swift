//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public class RecordingController {
    private let callCoordinatorController: CallCoordinatorController
    private let currentUser: User
    
    var onRecordingEvent: ((RecordingEvent) -> Void)?
    var onRecordingRequestedEvent: ((RecordingEvent) -> Void)?
        
    private var coordinatorClient: CoordinatorClient {
        callCoordinatorController.coordinatorClient
    }
    
    init(
        callCoordinatorController: CallCoordinatorController,
        currentUser: User
    ) {
        self.callCoordinatorController = callCoordinatorController
        self.currentUser = currentUser
    }
    
    public func startRecording(callId: String, callType: CallType) async throws {
        let callCid = "\(callType.name):\(callId)"
        let recordingEvent = RecordingEvent(callCid: callCid, type: callType.name, action: .requested)
        try await coordinatorClient.startRecording(callId: callId, callType: callType.name)
        onRecordingRequestedEvent?(recordingEvent)
    }
    
    public func stopRecording(callId: String, callType: CallType) async throws {
        try await coordinatorClient.stopRecording(callId: callId, callType: callType.name)
    }
    
    public func listRecordings(
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
    
    public func recordingEvents() -> AsyncStream<RecordingEvent> {
        let events = AsyncStream(RecordingEvent.self) { [weak self] continuation in
            self?.onRecordingEvent = { event in
                continuation.yield(event)
            }
        }
        return events
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
