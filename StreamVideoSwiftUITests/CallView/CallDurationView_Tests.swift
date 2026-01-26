//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@MainActor
final class CallDurationView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var viewModel: CallViewModel! = .init()

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        viewModel.startCall(
            callType: .default,
            callId: UUID().uuidString,
            members: [],
            ring: true
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Rendering based on viewModel.call.state.duration

    func test_callDurationView_durationIsLessThanZero_viewWasConfiguredCorrectly() throws {
        viewModel.call?.state.duration = -100
        assertSubject(makeSubject)
    }

    func test_callDurationView_durationIsZero_viewWasConfiguredCorrectly() throws {
        assertSubject(makeSubject)
    }

    func test_callDurationView_durationIsGreaterThanZero_viewWasConfiguredCorrectly() throws {
        viewModel.call?.state.duration = 100
        assertSubject(makeSubject)
    }

    func test_callDurationView_durationIsGreaterThanZeroAndCallIsRecording_viewWasConfiguredCorrectly() throws {
        viewModel.call?.state.duration = 100
        viewModel.recordingState = .recording
        assertSubject(makeSubject)
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func makeSubject() -> some View {
        CallDurationView(viewModel)
            .frame(width: 100, height: 50)
    }

    private func assertSubject(
        @ViewBuilder _ subject: () -> some View,
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        AssertSnapshot(
            subject(),
            variants: snapshotVariants,
            size: sizeThatFits,
            line: line,
            file: file,
            function: function
        )
    }
}
