//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class PeerConnectionClientEventScenarios_Tests: XCTestCase, @unchecked Sendable {

    func test_subscribeICEFailure_reportsPeerConnectionConnectFailure() async {
        let reporter = MockClientEventReporter()
        let stateSubject = CurrentValueSubject<RTCPeerConnectionState, Never>(.new)
        let iceStateSubject = CurrentValueSubject<RTCIceConnectionState, Never>(.new)
        let subject = WebRTCPeerConnectionConnectReporter(
            peerConnectionType: .subscriber,
            statePublisher: stateSubject.eraseToAnyPublisher(),
            iceStatePublisher: iceStateSubject.eraseToAnyPublisher(),
            reporter: reporter,
            wasPreviouslyConnected: true,
            details: .init(
                sfuId: "sfu-1",
                callSessionId: "call-session-1",
                coordinatorConnectId: "coordinator-connect-1"
            )
        )

        stateSubject.send(.connecting)
        iceStateSubject.send(.failed)

        await fulfillment {
            await reporter.completedStages.contains {
                $0.attempt.stage == .peerConnectionConnect
            }
        }
        let trace = await ClientEventTrace(reporter: reporter)
        trace.assertCompleted(
            .peerConnectionConnect,
            outcome: .failure,
            retryCount: 0,
            failureCode: ClientEventFailureCode.iceConnectivityFailed.rawValue
        )
        XCTAssertEqual(trace.begun(.peerConnectionConnect).first?.peerConnection, .subscribe)
        XCTAssertEqual(
            trace.begun(.peerConnectionConnect).first?.details.wasPreviouslyConnected,
            true
        )
        XCTAssertEqual(trace.completed(.peerConnectionConnect).first?.details.iceState, .failed)
        subject.stop()
    }
}
