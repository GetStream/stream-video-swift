//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public struct VideoRenderingOptions: InjectionKey, Sendable, CustomStringConvertible {
    public nonisolated(unsafe) static var currentValue: Self = .init()

    public let renderingBackend: RTCVideoRenderingBackend
    public let bufferPolicy: RTCFrameBufferPolicy
    public let maxInFlightFrames: Int
    public let rotationOverride: RTCVideoRotation?

    public var description: String {
        var result = "{"
        result += " renderingBackend:\(renderingBackend)"
        result += ", bufferPolicy:\(bufferPolicy)"
        result += ", maxInFlightFrames:\(maxInFlightFrames)"
        result += ", rotationOverride:\(rotationOverride)"
        result += " }"
        return result
    }

    public init(
        renderingBackend: RTCVideoRenderingBackend = .default,
        bufferPolicy: RTCFrameBufferPolicy = .none,
        maxInFlightFrames: Int = 0,
        rotationOverride: RTCVideoRotation? = nil
    ) {
        self.renderingBackend = renderingBackend
        self.bufferPolicy = bufferPolicy
        self.maxInFlightFrames = maxInFlightFrames
        self.rotationOverride = rotationOverride
    }
}

extension InjectedValues {
    public var videoRenderingOptions: VideoRenderingOptions {
        get { Self[VideoRenderingOptions.self] }
        set { Self[VideoRenderingOptions.self] = newValue }
    }
}

extension RTCVideoRenderingBackend: @retroactive CustomStringConvertible {
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
    public var description: String {
        switch self {
        case .none:
            return ".none"
        case .wrapOnlyExistingNV12:
            return ".wrapOnlyExistingNV12"
        case .copyToNV12:
            return "copyToNV12"
        case .convertWithPoolToNV12:
            return ".convertWithPoolToNV12"
        @unknown default:
            return ".unknown"
        }
    }
}

extension RTCVideoRotation: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case ._0:
            return "._0"
        case ._90:
            return "._90"
        case ._180:
            return "_180"
        case ._270:
            return "._270"
        @unknown default:
            return ".unknown"
        }
    }
}
