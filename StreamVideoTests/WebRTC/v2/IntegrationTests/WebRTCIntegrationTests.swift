//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@preconcurrency import XCTest

final class WebRTCIntegrationTests: XCTestCase, @unchecked Sendable {

    struct Operation {
        var delay: TimeInterval = 0
        var operation: @Sendable () async throws -> Void
    }

    private enum FlowOperation {
        case `default`(Operation)
        case concurrent([Operation])

        static func buildDefault(
            delay: TimeInterval = 0,
            operation: @Sendable @escaping () async throws -> Void
        ) -> FlowOperation {
            .default(.init(delay: delay, operation: operation))
        }
    }

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()
    private lazy var mockStack: MockWebRTCCoordinatorStack! = .init(videoConfig: Self.videoConfig)
    private var stateAdapter: WebRTCStateAdapter { mockStack.coordinator.stateAdapter }
    private var subject: WebRTCCoordinator { mockStack.coordinator }

    override func tearDown() {
        mockStack = nil
        super.tearDown()
    }

    // MARK: - Track assignment

    func test_multipleUsersJoined_participantsUpdatedAsExpected() async throws {
        try await flowExecution(
            of: [
                // -- Connecting
                .buildDefault {
                    self.stubCallAuthentication(
                        .success(
                            (
                                self.mockStack.sfuStack.adapter,
                                JoinCallResponse.dummy(call: .dummy(cid: self.mockStack.callCid))
                            )
                        )
                    )
                },
                .concurrent(
                    [
                        .init {
                            try await self.subject.connect(
                                callSettings: nil,
                                options: nil,
                                ring: false,
                                notify: false,
                                source: .inApp
                            )
                        },
                        .init {
                            self.mockStack.webRTCAuthenticator.stub(
                                for: .waitForAuthentication,
                                with: Result<
                                    Void,
                                    Error
                                >.success(())
                            )
                        }
                    ]
                ),
                
                // -- Joining
                .concurrent(
                    [
                        .init(delay: 0.5) {
                            self.mockStack.joinResponse(
                                [.dummy(id: await self.stateAdapter.sessionID)]
                            )
                        },
                        .init {
                            self.mockStack.webRTCAuthenticator.stub(
                                for: .waitForConnect,
                                with: Result<Void, Error>.success(())
                            )
                        }
                    ]
                ),
                .buildDefault(delay: 0.5) {}, // Wait for the stage transition to complete
                .concurrent(
                    [
                        .init {
                            self.mockStack.receiveHealthCheck(every: 2)
                        },
                        .init {
                            self.mockStack.webRTCAuthenticator.stub(
                                for: .waitForConnect,
                                with: Result<
                                    Void,
                                    Error
                                >.success(())
                            )
                        }
                    ]
                ),
                
                // -- Joined
                .concurrent([
                    .init {
                        self.mockStack.participantJoined(.dummy(id: "2"))
                    },
                    .init { self.mockStack.participantJoined(.dummy(id: "3")) },
                    .init { await self.mockStack.addTrack(kind: .video, for: "2") },
                    .init { await self.mockStack.addTrack(kind: .audio, for: "2") },
                    .init { await self.mockStack.addTrack(kind: .video, for: "3") }
                ])
            ]
        )

        await fulfillment {
            let no2HasTrack = await self.stateAdapter.participants["2"]?.track != nil
            let no3HasTrack = await self.stateAdapter.participants["3"]?.track != nil
            return no2HasTrack && no3HasTrack
        }
    }

    // MARK: - Flow Helpers

    private func stubCallAuthentication(
        _ result: Result<(SFUAdapter, JoinCallResponse), Error>
    ) {
        mockStack
            .webRTCAuthenticator
            .stub(
                for: .authenticate,
                with: result
            )
    }

    // MARK: - Private Helpers

    private func flowExecution(
        of operations: [FlowOperation]
    ) async throws {
        for operation in operations {
            switch operation {
            case let .default(item):
                if item.delay > 0 {
                    await wait(for: item.delay)
                }
                try await item.operation()
            case let .concurrent(operations):
                try await withThrowingTaskGroup(of: Void.self) { group in
                    operations.forEach { item in
                        group.addTask {
                            if item.delay > 0 {
                                await self.wait(for: item.delay)
                            }
                            try await item.operation()
                        }
                    }
                    try await group.waitForAll()
                }
            }
        }
    }
}
