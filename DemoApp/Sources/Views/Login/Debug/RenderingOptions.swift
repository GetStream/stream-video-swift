//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

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
