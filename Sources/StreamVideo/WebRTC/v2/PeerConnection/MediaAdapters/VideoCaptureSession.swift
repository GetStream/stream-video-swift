//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

struct VideoCaptureSession {
    var position: AVCaptureDevice.Position

    var device: AVCaptureDevice?

    /// The local video track for the screen share.
    var localTrack: RTCVideoTrack

    /// The video capturer for the screen share.
    var capturer: StreamVideoCapturing
}

/// A class that provides and manages the active screen sharing session.
final class VideoCaptureSessionProvider {

    /// The currently active screen sharing session, if any.
    ///
    /// When set to nil, it automatically stops the capture of the previous session.
    var activeSession: VideoCaptureSession? {
        didSet {
            if activeSession == nil {
                Task {
                    do {
                        try await oldValue?.capturer.stopCapture()
                    } catch {
                        log.error(error)
                    }
                }
            }
        }
    }

    /// Cleans up resources when the instance is deallocated.
    ///
    /// This deinitializer ensures that any active capture is stopped when the provider is destroyed.
    deinit {
        Task { [activeSession] in
            do {
                try await activeSession?.capturer.stopCapture()
            } catch {
                log.error(error)
            }
        }
    }
}

extension AVCaptureDevice.Position: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unspecified:
            return ".unspecified"
        case .back:
            return ".back"
        case .front:
            return ".front"
        @unknown default:
            return ".unknown(\(rawValue)"
        }
    }
}
