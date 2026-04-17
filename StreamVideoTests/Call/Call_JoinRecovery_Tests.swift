//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@preconcurrency import XCTest

@MainActor
final class Call_JoinRecovery_Tests: StreamVideoTestCase, @unchecked Sendable {

    func test_join_afterInitialJoinAndSubscriberDisconnects_capsBackendJoinRequestsAfterTenRejoins() async throws {
        let mockPermissions = MockPermissionsStore()
        defer { mockPermissions.dismantle() }
        let maxRejoinAttempts = 10
        let expectedJoinCallAttempts = maxRejoinAttempts + 1

        let callType = "livestream"
        let callId = String.unique
        let defaultAPI = MockDefaultAPIEndpoints()
        let videoConfig = VideoConfig.dummy()
        let webRTCCoordinatorFactory = MockWebRTCCoordinatorFactory(
            videoConfig: videoConfig
        )
        let controller = CallController(
            defaultAPI: defaultAPI,
            user: .dummy(),
            callId: callId,
            callType: callType,
            apiKey: .unique,
            videoConfig: videoConfig,
            initialCallSettings: .default,
            cachedLocation: .unique,
            webRTCCoordinatorFactory: webRTCCoordinatorFactory
        )
        let subject = Call(
            callType: callType,
            callId: callId,
            coordinatorClient: defaultAPI,
            callController: controller
        )
        let joinResponse = JoinCallResponse.dummy(
            call: .dummy(
                cid: subject.cId,
                id: subject.callId,
                type: subject.callType
            ),
            credentials: .dummy(server: .dummy(edgeName: "test-sfu")),
            ownCapabilities: [.sendAudio, .sendVideo]
        )
        let subscriberDisconnected = PassthroughSubject<Void, Never>()
        let subscriber = try XCTUnwrap(
            MockRTCPeerConnectionCoordinator(
                peerType: .subscriber,
                sfuAdapter: webRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .sfuStack
                    .adapter
            )
        )
        subscriber.stub(
            for: \.disconnectedPublisher,
            with: subscriberDisconnected.eraseToAnyPublisher()
        )
        defaultAPI.stub(for: .joinCall, with: joinResponse)
        webRTCCoordinatorFactory
            .mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.subscriber] = subscriber
        webRTCCoordinatorFactory
            .mockCoordinatorStack
            .coordinator
            .stateMachine
            .currentStage
            .context
            .authenticator = CallAuthenticationBackedWebRTCAuthenticator(
                sfuAdapter: webRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .sfuStack
                    .adapter
            )

        let joinTask = Task {
            try await subject.join(
                create: false,
                ring: false,
                notify: false,
                callSettings: .init(audioOn: false, videoOn: false)
            )
        }

        await fulfilmentInMainActor(timeout: defaultTimeout) {
            webRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateMachine
                .currentStage
                .id == .joining
        }

        webRTCCoordinatorFactory
            .mockCoordinatorStack
            .sfuStack
            .setConnectionState(to: .connected(healthCheckInfo: .init()))
        webRTCCoordinatorFactory.mockCoordinatorStack.joinResponse([])

        _ = try await joinTask.value

        XCTAssertEqual(defaultAPI.timesCalled(.joinCall), 1)

        for _ in 0..<maxRejoinAttempts {
            subscriberDisconnected.send(())

            let nextJoinCallCount = defaultAPI.timesCalled(.joinCall) + 1
            await fulfilmentInMainActor(timeout: defaultTimeout + 2) {
                defaultAPI.timesCalled(.joinCall) >= nextJoinCallCount
                    && webRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .coordinator
                    .stateMachine
                    .currentStage
                    .id == .joining
            }

            webRTCCoordinatorFactory
                .mockCoordinatorStack
                .sfuStack
                .setConnectionState(to: .connected(healthCheckInfo: .init()))
            webRTCCoordinatorFactory.mockCoordinatorStack.joinResponse([])

            await fulfilmentInMainActor(timeout: defaultTimeout) {
                webRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .coordinator
                    .stateMachine
                    .currentStage
                    .id == .joined
            }
        }

        XCTAssertEqual(defaultAPI.timesCalled(.joinCall), expectedJoinCallAttempts)

        subscriberDisconnected.send(())

        await fulfilmentInMainActor(timeout: defaultTimeout + 3) {
            webRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateMachine
                .currentStage
                .id == .idle
        }

        let joinCallRequests = try XCTUnwrap(
            defaultAPI.recordedInputPayload(
                (String, String, JoinCallRequest).self,
                for: .joinCall
            )
        )

        XCTAssertEqual(joinCallRequests.count, expectedJoinCallAttempts)
        XCTAssertTrue(joinCallRequests.allSatisfy { $0.2.create == false })
        XCTAssertTrue(joinCallRequests.allSatisfy { $0.2.ring == false })
        XCTAssertTrue(joinCallRequests.allSatisfy { $0.2.notify == false })
    }

    func test_join_afterAbnormalWebSocketClosure_issuesAdditionalBackendJoinRequest() async throws {
        let mockPermissions = MockPermissionsStore()
        defer { mockPermissions.dismantle() }

        let callType = "livestream"
        let callId = String.unique
        let defaultAPI = MockDefaultAPIEndpoints()
        let videoConfig = VideoConfig.dummy()
        let webRTCCoordinatorFactory = MockWebRTCCoordinatorFactory(
            videoConfig: videoConfig
        )
        let controller = CallController(
            defaultAPI: defaultAPI,
            user: .dummy(),
            callId: callId,
            callType: callType,
            apiKey: .unique,
            videoConfig: videoConfig,
            initialCallSettings: .default,
            cachedLocation: .unique,
            webRTCCoordinatorFactory: webRTCCoordinatorFactory
        )
        let subject = Call(
            callType: callType,
            callId: callId,
            coordinatorClient: defaultAPI,
            callController: controller
        )
        let joinResponse = JoinCallResponse.dummy(
            call: .dummy(
                cid: subject.cId,
                id: subject.callId,
                type: subject.callType
            ),
            credentials: .dummy(server: .dummy(edgeName: "test-sfu")),
            ownCapabilities: [.sendAudio, .sendVideo]
        )
        let publisher = try XCTUnwrap(
            MockRTCPeerConnectionCoordinator(
                peerType: .publisher,
                sfuAdapter: webRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .sfuStack
                    .adapter
            )
        )
        let subscriber = try XCTUnwrap(
            MockRTCPeerConnectionCoordinator(
                peerType: .subscriber,
                sfuAdapter: webRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .sfuStack
                    .adapter
            )
        )
        let refreshedWebSocket = MockWebSocketClient(webSocketClientType: .sfu)
        defaultAPI.stub(for: .joinCall, with: joinResponse)
        webRTCCoordinatorFactory
            .mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.publisher] = publisher
        webRTCCoordinatorFactory
            .mockCoordinatorStack
            .rtcPeerConnectionCoordinatorFactory
            .stubbedBuildCoordinatorResult[.subscriber] = subscriber
        webRTCCoordinatorFactory
            .mockCoordinatorStack
            .sfuStack
            .webSocketFactory
            .stub(for: .build, with: refreshedWebSocket)
        webRTCCoordinatorFactory
            .mockCoordinatorStack
            .coordinator
            .stateMachine
            .currentStage
            .context
            .authenticator = CallAuthenticationBackedWebRTCAuthenticator(
                sfuAdapter: webRTCCoordinatorFactory
                    .mockCoordinatorStack
                    .sfuStack
                    .adapter
            )

        let joinTask = Task {
            try await subject.join(
                create: false,
                ring: false,
                notify: false,
                callSettings: .init(audioOn: false, videoOn: false)
            )
        }

        await fulfilmentInMainActor(timeout: defaultTimeout) {
            webRTCCoordinatorFactory
                .mockCoordinatorStack
                .coordinator
                .stateMachine
                .currentStage
                .id == .joining
        }

        webRTCCoordinatorFactory
            .mockCoordinatorStack
            .sfuStack
            .setConnectionState(to: .connected(healthCheckInfo: .init()))
        webRTCCoordinatorFactory.mockCoordinatorStack.joinResponse([])

        _ = try await joinTask.value

        XCTAssertEqual(defaultAPI.timesCalled(.joinCall), 1)

        webRTCCoordinatorFactory.mockCoordinatorStack.sfuStack.setConnectionState(
            to: .disconnected(source: .serverInitiated())
        )
        refreshedWebSocket.simulate(state: .connected(healthCheckInfo: .init()))
        refreshedWebSocket.eventSubject.send(.sfuEvent(.joinResponse(.init())))

        await fulfilmentInMainActor(timeout: defaultTimeout + 2) {
            defaultAPI.timesCalled(.joinCall) >= 2
        }

        let joinCallRequests = try XCTUnwrap(
            defaultAPI.recordedInputPayload(
                (String, String, JoinCallRequest).self,
                for: .joinCall
            )
        )

        XCTAssertGreaterThanOrEqual(joinCallRequests.count, 2)
        XCTAssertTrue(joinCallRequests.allSatisfy { $0.2.create == false })
        XCTAssertTrue(joinCallRequests.allSatisfy { $0.2.ring == false })
        XCTAssertTrue(joinCallRequests.allSatisfy { $0.2.notify == false })
    }
}

private final class CallAuthenticationBackedWebRTCAuthenticator:
    WebRTCAuthenticating,
    @unchecked Sendable {
    @Injected(\.audioStore) private var audioStore

    private let sfuAdapter: SFUAdapter

    init(sfuAdapter: SFUAdapter) {
        self.sfuAdapter = sfuAdapter
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
        let response = try await coordinator.callAuthentication(
            create,
            ring,
            currentSFU,
            migratingFromList,
            notify,
            options
        )

        await coordinator.stateAdapter.set(token: response.credentials.token)
        await coordinator.stateAdapter.enqueueOwnCapabilities {
            Set(response.ownCapabilities)
        }
        await coordinator.stateAdapter.set(
            audioSettings: response.call.settings.audio
        )
        await coordinator.stateAdapter.set(
            connectOptions: ConnectOptions(
                iceServers: response.credentials.iceServers
            )
        )

        let initialCallSettings = await coordinator.stateAdapter.initialCallSettings
        let remoteCallSettings = CallSettings(response.call.settings)
        let callSettings = {
            var result = initialCallSettings ?? remoteCallSettings
            if audioStore.state.currentRoute.isExternal, result.speakerOn {
                result = result.withUpdatedSpeakerState(false)
            }
            if result.audioOn, !response.ownCapabilities.contains(.sendAudio) {
                result = result.withUpdatedAudioState(false)
            }
            if result.videoOn, !response.ownCapabilities.contains(.sendVideo) {
                result = result.withUpdatedVideoState(false)
            }
            return result
        }()

        await coordinator.stateAdapter.enqueueCallSettings { _ in callSettings }
        await coordinator.stateAdapter.set(
            videoOptions: .init(preferredCameraPosition: {
                switch response.call.settings.video.cameraFacing {
                case .back:
                    return .back
                case .external, .front, .unknown:
                    return .front
                }
            }())
        )
        await coordinator.stateAdapter.set(
            isTracingEnabled: response.statsOptions.enableRtcStats
        )

        let statsReportingInterval = response.statsOptions.reportingIntervalMs
            / 1000
        if let statsReporter = await coordinator.stateAdapter.statsAdapter {
            statsReporter.deliveryInterval = TimeInterval(statsReportingInterval)
        } else {
            let unifiedSessionID = await coordinator.stateAdapter.unifiedSessionId
            let trackStorage = await coordinator.stateAdapter.trackStorage
            let statsReporter = WebRTCStatsAdapter(
                sessionID: await coordinator.stateAdapter.sessionID,
                unifiedSessionID: unifiedSessionID,
                isTracingEnabled: await coordinator.stateAdapter.isTracingEnabled,
                trackStorage: trackStorage
            )
            statsReporter.deliveryInterval = TimeInterval(statsReportingInterval)
            await coordinator.stateAdapter.set(statsAdapter: statsReporter)
        }

        return (sfuAdapter, response)
    }

    func waitForAuthentication(on sfuAdapter: SFUAdapter) async throws {}

    func waitForConnect(on sfuAdapter: SFUAdapter) async throws {}
}
