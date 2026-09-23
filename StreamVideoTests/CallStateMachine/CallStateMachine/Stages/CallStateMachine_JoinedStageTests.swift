//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class CallStateMachineStageJoinedStage_Tests: StreamVideoTestCase, @unchecked Sendable {

    private struct TestError: Error {}

    private lazy var callController: MockCallController! = .init()
    private lazy var call: Call! = .dummy(callController: callController)
    private lazy var allOtherStages: [Call.StateMachine.Stage]! = Call.StateMachine.Stage.ID
        .allCases
        .filter { $0 != subject.id }
        .map { Call.StateMachine.Stage(id: $0, context: .init(call: call)) }
    private lazy var validOtherStages: Set<Call.StateMachine.Stage.ID>! = [
        .joining
    ]
    private lazy var response: JoinCallResponse! = .dummy()
    private lazy var subject: Call.StateMachine.Stage! = .joined(.init(call: call), response: response)

    override func tearDown() async throws {
        subject = nil
        allOtherStages = nil
        validOtherStages = nil
        response = nil
        call = nil
        callController = nil
        await MainActor.run {}
        try await super.tearDown()
    }

    // MARK: - Test Initialization

    func testInitialization() {
        XCTAssertEqual(subject.id, .joined)
        XCTAssertTrue(subject.context.call === call)
        XCTAssertEqual(subject.context.output.joinResponse, response)
    }

    // MARK: - Test Transition

    func testTransition() {
        for nextStage in allOtherStages {
            if validOtherStages.contains(nextStage.id) {
                XCTAssertNotNil(subject.transition(from: nextStage))
            } else {
                XCTAssertNil(subject.transition(from: nextStage), "No error was thrown for \(nextStage.id)")
            }
        }
    }

    // MARK: - CallSettings observation

    func test_joiningTransition_callSettingsChange_managersSynchronize() async {
        _ = subject.transition(from: .init(id: .joining, context: .init(call: call)))

        await fulfillment {
            self.callController.timesCalled(.updateOwnCapabilities) > 0
        }

        await MainActor.run {
            call.state.ownCapabilities = [.sendAudio]
            call.state.update(
                callSettings: .init(
                    audioOn: false,
                    videoOn: false,
                    speakerOn: false,
                    audioOutputOn: false,
                    cameraPosition: .back
                )
            )
        }

        await fulfilmentInMainActor {
            self.call.microphone.status == .disabled
                && self.call.camera.status == .disabled
                && self.call.camera.direction == .back
        }
    }

    // MARK: - OwnCapabilities observation

    func test_joiningTransition_ownCapabilitiesChanged_controllerReceivesUpdate() async {
        let coordinatorFactory = MockWebRTCCoordinatorFactory(videoConfig: .dummy())
        await coordinatorFactory.mockCoordinatorStack.coordinator.stateAdapter
            .enqueueOwnCapabilities { [.sendAudio] }
        callController = .init(
            defaultAPI: MockDefaultAPIEndpoints(),
            user: .dummy(),
            callId: .unique,
            callType: .unique,
            apiKey: .unique,
            videoConfig: .dummy(),
            initialCallSettings: .default,
            cachedLocation: nil,
            webRTCCoordinatorFactory: coordinatorFactory
        )

        await MainActor.run {
            call.state.ownCapabilities = [.sendAudio]
        }

        _ = subject.transition(from: .init(id: .joining, context: .init(call: call)))

        await fulfillment {
            self.callController
                .recordedInputPayload([OwnCapability].self, for: .updateOwnCapabilities)?
                .contains([.sendAudio]) ?? false
        }
    }
}

extension Call.StateMachine.Stage.Context.Output {
    var joinResponse: JoinCallResponse? {
        switch self {
        case let .joined(output):
            return output
        default:
            return nil
        }
    }
}
