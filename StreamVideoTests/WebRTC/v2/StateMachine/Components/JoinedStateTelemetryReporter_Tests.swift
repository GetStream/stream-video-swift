//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class JoinedStateTelemetryReporter_Tests: XCTestCase, @unchecked Sendable {

    private let sessionId: String = .unique
    private let unifiedSessionId: String = .unique

    // MARK: - regular

    func test_reportTelemetry_regular_sendsConnectionTime() async throws {
        let (subject, sfuStack) = makeSubject(flowType: .regular)

        let telemetry = try await reportTelemetry(subject, sfuStack: sfuStack)

        switch telemetry.data {
        case let .connectionTimeSeconds(value):
            XCTAssertGreaterThan(value, 0)
        default:
            XCTFail("Unexpected telemetry data \(String(describing: telemetry.data)).")
        }
    }

    // MARK: - reconnections

    func test_reportTelemetry_fast_sendsStrategyAndDuration() async throws {
        let (subject, sfuStack) = makeSubject(flowType: .fast)

        let telemetry = try await reportTelemetry(subject, sfuStack: sfuStack)

        try assertReconnection(telemetry, strategy: .fast)
    }

    func test_reportTelemetry_rejoin_sendsStrategyAndDuration() async throws {
        let (subject, sfuStack) = makeSubject(flowType: .rejoin)

        let telemetry = try await reportTelemetry(subject, sfuStack: sfuStack)

        try assertReconnection(telemetry, strategy: .rejoin)
    }

    func test_reportTelemetry_migrate_sendsStrategyAndDuration() async throws {
        let (subject, sfuStack) = makeSubject(flowType: .migrate)

        let telemetry = try await reportTelemetry(subject, sfuStack: sfuStack)

        try assertReconnection(telemetry, strategy: .migrate)
    }

    // MARK: - session identifiers

    func test_reportTelemetry_forwardsSessionIdentifiers() async throws {
        let (subject, sfuStack) = makeSubject(flowType: .fast)

        _ = try await reportTelemetry(subject, sfuStack: sfuStack)

        let request = try XCTUnwrap(sfuStack.service.sendStatsWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.unifiedSessionID, unifiedSessionId)
    }

    // MARK: - Private

    private func makeSubject(
        flowType: JoinedStateTelemetryReporter.FlowType
    ) -> (JoinedStateTelemetryReporter, MockSFUStack) {
        var subject = JoinedStateTelemetryReporter()
        subject.flowType = flowType
        return (subject, MockSFUStack())
    }

    private func reportTelemetry(
        _ subject: JoinedStateTelemetryReporter,
        sfuStack: MockSFUStack,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> Stream_Video_Sfu_Signal_Telemetry {
        /// The reported duration is measured from the moment the reporter was
        /// created, so we let some time pass to assert on a non-zero value.
        await wait(for: 0.1)
        await subject.reportTelemetry(
            sessionId: sessionId,
            unifiedSessionId: unifiedSessionId,
            sfuAdapter: sfuStack.adapter
        )
        return try XCTUnwrap(
            sfuStack.service.sendStatsWasCalledWithRequest?.telemetry,
            file: file,
            line: line
        )
    }

    private func assertReconnection(
        _ telemetry: Stream_Video_Sfu_Signal_Telemetry,
        strategy: Stream_Video_Sfu_Models_WebsocketReconnectStrategy,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        switch telemetry.data {
        case let .reconnection(reconnection):
            XCTAssertEqual(reconnection.strategy, strategy, file: file, line: line)
            /// The duration used to be dropped for `.fast`, because the branch
            /// shadowed the reconnection value that carried it.
            XCTAssertGreaterThan(reconnection.timeSeconds, 0, file: file, line: line)
        default:
            XCTFail(
                "Unexpected telemetry data \(String(describing: telemetry.data)).",
                file: file,
                line: line
            )
        }
    }
}
