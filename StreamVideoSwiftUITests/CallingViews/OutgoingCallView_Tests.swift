//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class OutgoingCallView_Tests: StreamVideoUITestCase {
    
    func test_outgoingCallView_snapshot() throws {
        let view = OutgoingCallView(viewModel: CallViewModel())
        AssertSnapshot(view)
    }
}
