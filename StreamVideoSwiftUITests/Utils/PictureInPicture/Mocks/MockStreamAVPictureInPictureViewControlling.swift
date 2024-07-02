//
//  MockStreamAVPictureInPictureViewControlling.swift
//  StreamVideoSwiftUITests
//
//  Created by Ilias Pavlidakis on 15/7/24.
//

import Foundation
import StreamWebRTC
@testable import StreamVideoSwiftUI

final class MockStreamAVPictureInPictureViewControlling: StreamAVPictureInPictureViewControlling {
    var onSizeUpdate: ((CGSize) -> Void)?
    var track: RTCVideoTrack?
    var preferredContentSize: CGSize = .zero
    var displayLayer: CALayer = .init()
}

