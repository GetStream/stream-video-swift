//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

extension AppEnvironment {

    /// Debug menu options for the WebRTC video rendering backend.
    enum VideoRenderingBackend: Hashable, Debuggable, Sendable, CaseIterable {
        case `default`
        case sharedMetal

        /// Maps the debug option to the underlying WebRTC backend.
        var rawBackend: RTCVideoRenderingBackend {
            switch self {
            case .default:
                return .default
            case .sharedMetal:
                return .sharedMetal
            }
        }

        /// Title shown in the debug menu.
        var title: String {
            switch self {
            case .default:
                "Default"
            case .sharedMetal:
                "Shared Metal Pipeline"
            }
        }
    }

    /// Active override for the renderer backend used by the demo app.
    nonisolated(unsafe) static var videoRenderingBackend: VideoRenderingBackend = {
        switch InjectedValues[\.videoRenderingOptions].backend {
        case .default:
            return .default
        case .sharedMetal:
            return .sharedMetal
        @unknown default:
            return .default
        }
    }()

    /// Debug menu options for the WebRTC frame buffer policy.
    enum VideoRenderingBufferPolicy: Hashable, Debuggable, Sendable, CaseIterable {
        case none
        case wrapOnlyExistingNV12
        case copyToNV12
        case convertWithPoolToNV12

        /// Maps the debug option to the underlying WebRTC buffer policy.
        var rawPolicy: RTCFrameBufferPolicy {
            switch self {
            case .none:
                return .none
            case .wrapOnlyExistingNV12:
                return .wrapOnlyExistingNV12
            case .copyToNV12:
                return .copyToNV12
            case .convertWithPoolToNV12:
                return .convertWithPoolToNV12
            }
        }

        /// Title shown in the debug menu.
        var title: String {
            switch self {
            case .none:
                "None"
            case .wrapOnlyExistingNV12:
                "Wrap Only"
            case .copyToNV12:
                "Copy"
            case .convertWithPoolToNV12:
                "Convert & Copy"
            }
        }
    }

    /// Active override for how renderer buffers are produced.
    nonisolated(unsafe) static var videoRenderingBufferPolicy: VideoRenderingBufferPolicy = {
        switch InjectedValues[\.videoRenderingOptions].bufferPolicy {
        case .none:
            return .none
        case .wrapOnlyExistingNV12:
            return .wrapOnlyExistingNV12
        case .copyToNV12:
            return .copyToNV12
        case .convertWithPoolToNV12:
            return .convertWithPoolToNV12
        @unknown default:
            return .none
        }
    }()
}

extension DebugMenu {

    /// Debug menu entry for choosing video rendering options.
    struct VideoRenderingMenuView: View {

        @State private var backend = AppEnvironment.videoRenderingBackend {
            didSet { AppEnvironment.videoRenderingBackend = backend }
        }

        @State private var bufferPolicy = AppEnvironment.videoRenderingBufferPolicy {
            didSet { AppEnvironment.videoRenderingBufferPolicy = bufferPolicy }
        }

        var body: some View {
            Menu {
                backendMenu
                bufferPolicyMenu
            } label: {
                Text("Video Rendering")
            }
        }

        // MARK: - Private Helpers

        @ViewBuilder
        /// Selects the rendering backend.
        private var backendMenu: some View {
            ItemMenuView(
                items: AppEnvironment.VideoRenderingBackend.allCases,
                currentValue: backend,
                label: "Backend",
                availableAfterLogin: false,
                updater: { backend = $0 }
            )
        }

        @ViewBuilder
        /// Selects the renderer frame buffer policy.
        private var bufferPolicyMenu: some View {
            ItemMenuView(
                items: AppEnvironment.VideoRenderingBufferPolicy.allCases,
                currentValue: bufferPolicy,
                label: "Buffer Policy",
                availableAfterLogin: false,
                updater: { bufferPolicy = $0 }
            )
        }
    }
}
