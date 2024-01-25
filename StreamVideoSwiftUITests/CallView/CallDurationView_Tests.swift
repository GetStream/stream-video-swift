//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SwiftUI
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class CallDurationView_Tests: StreamVideoUITestCase {

    private lazy var viewModel: CallViewModel! = .init()

    override func setUp() {
        super.setUp()

        viewModel.startCall(
            callType: .default,
            callId: UUID().uuidString,
            members: [],
            ring: true
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
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
        file: StaticString = #file,
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

