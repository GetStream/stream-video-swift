//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import StreamWebRTC

final class MockStreamAVPictureInPictureViewControlling: StreamAVPictureInPictureViewControlling {
    var onSizeUpdate: ((CGSize) -> Void)?
    var track: RTCVideoTrack?
    var preferredContentSize: CGSize = .zero
    var displayLayer: CALayer = .init()
}
