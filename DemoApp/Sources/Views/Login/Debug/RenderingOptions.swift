//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamWebRTC
import SwiftUI

extension AppEnvironment {

    enum RenderingBackend: Hashable, Debuggable, Sendable, CaseIterable {
        case `default`
        case sharedMetal

        var rawBackend: RTCVideoRenderingBackend {
            switch self {
            case .default:
                return .default
            case .sharedMetal:
                return .sharedMetal
            }
        }

        var title: String {
            switch self {
            case .default:
                "Default"
            case .sharedMetal:
                "Shared Metal Pipeline"
            }
        }
    }

    nonisolated(unsafe) static var renderingBackend: RenderingBackend = .sharedMetal

    enum RenderingBufferPolicy: Hashable, Debuggable, Sendable, CaseIterable {
        case none
        case wrapOnlyExistingNV12
        case copyToNV12
        case convertWithPoolToNV12

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

        var title: String {
            switch self {
            case .none:
                "None"
            case .wrapOnlyExistingNV12:
                "Wrap Only"
            case .copyToNV12:
                "Copy"
            case .convertWithPoolToNV12:
                "Conver & Copy"
            }
        }
    }

    nonisolated(unsafe) static var renderingBufferPolicy: RenderingBufferPolicy = .convertWithPoolToNV12
}

extension DebugMenu {

    struct RenderingOptions: View {

        @State private var renderingBackend: AppEnvironment.RenderingBackend = AppEnvironment.renderingBackend {
            didSet {
                AppEnvironment.renderingBackend = renderingBackend
                InjectedValues[\.videoRenderingOptions] = .init(
                    renderingBackend: renderingBackend.rawBackend,
                    bufferPolicy: InjectedValues[\.videoRenderingOptions].bufferPolicy,
                    maxInFlightFrames: InjectedValues[\.videoRenderingOptions].maxInFlightFrames,
                    rotationOverride: InjectedValues[\.videoRenderingOptions].rotationOverride
                )
            }
        }

        @State private var renderingBufferPolicy: AppEnvironment.RenderingBufferPolicy = AppEnvironment.renderingBufferPolicy {
            didSet {
                AppEnvironment.renderingBufferPolicy = renderingBufferPolicy
                InjectedValues[\.videoRenderingOptions] = .init(
                    renderingBackend: InjectedValues[\.videoRenderingOptions].renderingBackend,
                    bufferPolicy: renderingBufferPolicy.rawPolicy,
                    maxInFlightFrames: InjectedValues[\.videoRenderingOptions].maxInFlightFrames,
                    rotationOverride: InjectedValues[\.videoRenderingOptions].rotationOverride
                )
            }
        }

        var body: some View {
            Menu {
                renderingBackendView
                renderingBufferPolicyView
            } label: {
                Text("Rendering Options")
            }
        }

        // MARK: - Private Helpers

        @ViewBuilder
        private var renderingBackendView: some View {
            DebugMenuItemView(
                label: "Rendering Backend",
                availableAfterLogin: false,
                items: AppEnvironment.RenderingBackend.allCases,
                currentValue: renderingBackend
            ) { self.renderingBackend = $0 }
        }

        @ViewBuilder
        private var renderingBufferPolicyView: some View {
            DebugMenuItemView(
                label: "Rendering Buffer Policy",
                availableAfterLogin: false,
                items: AppEnvironment.RenderingBufferPolicy.allCases,
                currentValue: renderingBufferPolicy
            ) { self.renderingBufferPolicy = $0 }
        }
    }
}
