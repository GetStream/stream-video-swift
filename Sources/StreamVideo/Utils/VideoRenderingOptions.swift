//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Configuration for how WebRTC video frames are rendered and buffered.
public struct VideoRenderingOptions: InjectionKey, Sendable, CustomStringConvertible {
    /// The injected default rendering options.
    public nonisolated(unsafe) static var currentValue: Self = .init()

    /// The WebRTC backend used to render video frames.
    public let backend: RTCVideoRenderingBackend
    /// The buffer policy used to prepare frames for rendering.
    public let bufferPolicy: RTCFrameBufferPolicy
    /// Limits in-flight frames for the renderer (0 uses the WebRTC default).
    public let maxInFlightFrames: Int

    /// A human-readable description of the rendering options.
    public var description: String {
        var result = "{"
        result += " backend:\(backend)"
        result += ", bufferPolicy:\(bufferPolicy)"
        result += ", maxInFlightFrames:\(maxInFlightFrames)"
        result += " }"
        return result
    }

    /// Creates rendering options with the specified configuration.
    /// - Parameters:
    ///   - backend: The WebRTC rendering backend to use.
    ///   - bufferPolicy: The frame buffer policy used by the renderer.
    ///   - maxInFlightFrames: Maximum number of in-flight frames (0 uses default).
    public init(
        backend: RTCVideoRenderingBackend = .sharedMetal,
        bufferPolicy: RTCFrameBufferPolicy = .copyToNV12,
        maxInFlightFrames: Int = 2
    ) {
        self.backend = backend
        self.bufferPolicy = bufferPolicy
        self.maxInFlightFrames = maxInFlightFrames
    }
}

extension InjectedValues {
    /// Accessor for the injected video rendering options.
    public var videoRenderingOptions: VideoRenderingOptions {
        get { Self[VideoRenderingOptions.self] }
        set { Self[VideoRenderingOptions.self] = newValue }
    }
}

extension RTCVideoRenderingBackend: @retroactive CustomStringConvertible {
    /// Debug-friendly description for logging.
    public var description: String {
        switch self {
        case .default:
            return ".default"
        case .sharedMetal:
            return ".sharedMetal"
        @unknown default:
            return ".unknown"
        }
    }
}

extension RTCFrameBufferPolicy: @retroactive CustomStringConvertible {
    /// Debug-friendly description for logging.
    public var description: String {
        switch self {
        case .none:
            return ".none"
        case .wrapOnlyExistingNV12:
            return ".wrapOnlyExistingNV12"
        case .copyToNV12:
            return ".copyToNV12"
        case .convertWithPoolToNV12:
            return ".convertWithPoolToNV12"
        @unknown default:
            return ".unknown"
        }
    }
}

extension RTCVideoRotation: @retroactive CustomStringConvertible {
    /// Debug-friendly description for logging.
    public var description: String {
        switch self {
        case ._0:
            return "._0"
        case ._90:
            return "._90"
        case ._180:
            return "._180"
        case ._270:
            return "._270"
        @unknown default:
            return ".unknown"
        }
    }
}
