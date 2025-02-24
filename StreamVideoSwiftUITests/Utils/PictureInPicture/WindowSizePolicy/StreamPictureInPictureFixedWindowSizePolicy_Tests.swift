//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import XCTest

final class StreamPictureInPictureFixedWindowSizePolicy_Tests: XCTestCase, @unchecked Sendable {
    
    private lazy var targetSize: CGSize! = .init(width: 100, height: 280)
    private lazy var subject: StreamPictureInPictureFixedWindowSizePolicy! = .init(targetSize)
    
    override func tearDown() {
        targetSize = nil
        subject = nil
        super.tearDown()
    }
    
    // MARK: - didSetController
    
    @MainActor
    func test_didSetTrackSize_setsPreferredContentSizeOnController() async {
        let controller = MockStreamAVPictureInPictureViewControlling()
        subject.controller = controller
        
        subject.trackSize = targetSize
        
        await fulfilmentInMainActor {
            controller.preferredContentSize == self.targetSize
        }
    }
}
