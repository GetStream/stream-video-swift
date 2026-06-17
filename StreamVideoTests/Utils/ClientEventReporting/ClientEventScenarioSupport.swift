//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

struct ClientEventTrace {
    let joinInitiatedDetails: [ClientEventStageDetails]
    let reportedEvents: [MockClientEventReporter.ReportedEvent]
    let begunStages: [MockClientEventReporter.BegunStage]
    let completedStages: [MockClientEventReporter.CompletedStage]

    init(reporter: MockClientEventReporter) async {
        joinInitiatedDetails = await reporter.reportJoinInitiatedDetails
        reportedEvents = await reporter.reportedEvents
        begunStages = await reporter.begunStages
        completedStages = await reporter.completedStages
    }

    func begun(_ stage: ClientEventStage) -> [MockClientEventReporter.BegunStage] {
        begunStages.filter { $0.stage == stage }
    }

    func completed(_ stage: ClientEventStage) -> [MockClientEventReporter.CompletedStage] {
        completedStages.filter { $0.attempt.stage == stage }
    }

    func assertCompleted(
        _ stage: ClientEventStage,
        outcome: ClientEventOutcome,
        retryCount: Int,
        failureCode: String? = nil,
        count: Int = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let begun = begun(stage)
        let completed = completed(stage)
        XCTAssertEqual(begun.count, count, file: file, line: line)
        XCTAssertEqual(completed.count, count, file: file, line: line)
        XCTAssertEqual(completed.last?.outcome, outcome, file: file, line: line)
        XCTAssertEqual(completed.last?.retryCount, retryCount, file: file, line: line)
        if let failureCode {
            XCTAssertEqual(completed.last?.failure?.code, failureCode, file: file, line: line)
        }
        if let last = completed.last {
            XCTAssertTrue(
                begun.contains { $0.attempt.stageId == last.attempt.stageId },
                file: file,
                line: line
            )
        }
    }

    func assertNotReported(
        _ stage: ClientEventStage,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(begun(stage).isEmpty, file: file, line: line)
        XCTAssertTrue(completed(stage).isEmpty, file: file, line: line)
        XCTAssertFalse(reportedEvents.contains { $0.stage == stage }, file: file, line: line)
    }
}

final class ClientEventScenarioHarness: @unchecked Sendable {
    let stack: MockWebRTCCoordinatorStack

    init(
        videoConfig: VideoConfig = .dummy(),
        callSettings: CallSettings = .default
    ) {
        stack = .init(videoConfig: videoConfig, callSettings: callSettings)
    }

    var trace: ClientEventTrace {
        get async { await .init(reporter: stack.clientEventReporter) }
    }

    func installSFUAdapter() async {
        await stack.coordinator.stateAdapter.set(sfuAdapter: stack.sfuStack.adapter)
    }

    func sendJoinResponse(_ response: Stream_Video_Sfu_Event_JoinResponse = .init()) {
        stack.sfuStack.receiveEvent(.sfuEvent(.joinResponse(response)))
    }
}

final class ScriptedWebRTCAuthenticator: WebRTCAuthenticating, @unchecked Sendable {
    private let lock = NSLock()
    private var authenticateResults: [Result<(SFUAdapter, JoinCallResponse), Error>]
    private var waitForAuthenticationResults: [Result<Void, Error>]
    private var waitForConnectResults: [Result<Void, Error>]

    init(
        authenticateResults: [Result<(SFUAdapter, JoinCallResponse), Error>] = [],
        waitForAuthenticationResults: [Result<Void, Error>] = [],
        waitForConnectResults: [Result<Void, Error>] = []
    ) {
        self.authenticateResults = authenticateResults
        self.waitForAuthenticationResults = waitForAuthenticationResults
        self.waitForConnectResults = waitForConnectResults
    }

    func authenticate(
        coordinator: WebRTCCoordinator,
        currentSFU: String?,
        migratingFromList: [String]?,
        create: Bool,
        ring: Bool,
        notify: Bool,
        options: CreateCallOptions?
    ) async throws -> (sfuAdapter: SFUAdapter, response: JoinCallResponse) {
        try pop(&authenticateResults).get()
    }

    func waitForAuthentication(on sfuAdapter: SFUAdapter) async throws {
        try pop(&waitForAuthenticationResults).get()
    }

    func waitForConnect(on sfuAdapter: SFUAdapter) async throws {
        try pop(&waitForConnectResults).get()
    }

    private func pop<T>(_ values: inout [Result<T, Error>]) throws -> Result<T, Error> {
        lock.lock()
        defer { lock.unlock() }
        guard values.isEmpty == false else {
            throw ClientError("ScriptedWebRTCAuthenticator has no remaining result.")
        }
        return values.removeFirst()
    }
}

enum SFUEventFactory {
    static func joinResponse(
        fastReconnectDeadlineSeconds: Int32 = 0
    ) -> Stream_Video_Sfu_Event_JoinResponse {
        var response = Stream_Video_Sfu_Event_JoinResponse()
        response.fastReconnectDeadlineSeconds = fastReconnectDeadlineSeconds
        return response
    }

    static func error(
        code: Stream_Video_Sfu_Models_ErrorCode,
        reconnectStrategy: Stream_Video_Sfu_Models_WebsocketReconnectStrategy = .unspecified
    ) -> Stream_Video_Sfu_Event_Error {
        var event = Stream_Video_Sfu_Event_Error()
        event.error.code = code
        event.reconnectStrategy = reconnectStrategy
        return event
    }

    static func goAway() -> Stream_Video_Sfu_Event_GoAway {
        Stream_Video_Sfu_Event_GoAway()
    }
}
