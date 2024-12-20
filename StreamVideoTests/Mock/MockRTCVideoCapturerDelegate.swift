//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamWebRTC

final class MockRTCVideoCapturerDelegate: NSObject, RTCVideoCapturerDelegate {
    private(set) var didCaptureWasCalledWith: (capturer: RTCVideoCapturer, frame: RTCVideoFrame)?

    func capturer(
        _ capturer: RTCVideoCapturer,
        didCapture frame: RTCVideoFrame
    ) {
        didCaptureWasCalledWith = (capturer, frame)
    }
}
