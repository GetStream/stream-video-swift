//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class CallConnectingView_Tests: StreamVideoUITestCase {
    
    func test_callConnectingView_snapshot() throws {
        let view = CallConnectingView(viewModel: CallViewModel(), title: "Test title 123")
        AssertSnapshot(view)
    }
}
