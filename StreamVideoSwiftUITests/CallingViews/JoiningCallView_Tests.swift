//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class JoiningCallView_Tests: StreamVideoUITestCase {
    
    func test_joiningCallView_snapshot() throws {
        let view = JoiningCallView(viewModel: CallViewModel())
        AssertSnapshot(view)
    }
}
