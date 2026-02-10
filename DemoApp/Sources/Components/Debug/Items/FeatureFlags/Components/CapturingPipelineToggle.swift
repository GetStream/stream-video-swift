//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension AppEnvironment {

    /// Debug-only toggle for enabling the new capturing pipeline path.
    enum CapturingPipelineToggle: Hashable, Debuggable {
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
    nonisolated(unsafe) static var usesNewCapturingPipeline: CapturingPipelineToggle = {
        AppEnvironment.configuration == .debug ? .enabled : .disabled
    }()
}

extension DebugMenu {

    struct CapturingPipelineToggleView: View {

        @State private var value = AppEnvironment.usesNewCapturingPipeline {
            didSet { AppEnvironment.usesNewCapturingPipeline = value }
        }

        var body: some View {
            ItemMenuView(
                items: [.enabled, .disabled],
                currentValue: value,
                label: "Capturing Pipeline",
                availableAfterLogin: false,
                updater: { value = $0 }
            )
        }
    }
}
