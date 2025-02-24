//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import StreamWebRTC

@MainActor
final class MockStreamAVPictureInPictureViewControlling: StreamAVPictureInPictureViewControlling {
    var onSizeUpdate: (@Sendable(CGSize) -> Void)?
    var track: RTCVideoTrack?
    var preferredContentSize: CGSize = .zero
    var displayLayer: CALayer = .init()
}
