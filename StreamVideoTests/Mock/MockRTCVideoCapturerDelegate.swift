//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

//
//  MockRTCVideoCapturerDelegate.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 19/9/24.
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
