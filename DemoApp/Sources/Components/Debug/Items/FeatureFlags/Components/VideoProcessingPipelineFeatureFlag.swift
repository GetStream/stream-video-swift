//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension AppEnvironment {

    /// Debug-only toggle for enabling the video processing pipeline path.
    enum VideProcessingPipelineToggle: Hashable, Debuggable {
        case enabled, disabled

        var title: String {
            switch self {
            case .enabled:
                return "Enabled"
            case .disabled:
                return "Disabled"
            }
        }
    }

    /// Default to enabled in debug builds so the pipeline is exercised during development.
    nonisolated(unsafe) static var usesVideoProcessingPipeline: VideProcessingPipelineToggle = {
        AppEnvironment.configuration == .debug ? .enabled : .disabled
    }()
}

extension DebugMenu {

    struct VideoProcessingPipelineToggleView: View {

        @State private var value = AppEnvironment.usesVideoProcessingPipeline {
            didSet { AppEnvironment.usesVideoProcessingPipeline = value }
        }

        var body: some View {
            ItemMenuView(
                items: [.enabled, .disabled],
                currentValue: value,
                label: "VideoProcessing Pipeline",
                availableAfterLogin: false,
                updater: { value = $0 }
            )
        }
    }
}
