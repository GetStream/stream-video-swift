//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

extension AppEnvironment {

    /// Debug-only toggle for enabling the new capturing pipeline path.
    enum SimulcastSupport: Hashable, Debuggable {
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
    nonisolated(unsafe) static var simulcastSupport: SimulcastSupport = {
        VideoConfig().simulcastSupport ? .enabled : .disabled
    }()
}

extension DebugMenu {

    struct SimulcastSupportToggleView: View {

        @State private var value = AppEnvironment.simulcastSupport {
            didSet { AppEnvironment.simulcastSupport = value }
        }

        var body: some View {
            ItemMenuView(
                items: [.enabled, .disabled],
                currentValue: value,
                label: "Simulcast support",
                availableAfterLogin: false,
                updater: { value = $0 }
            )
        }
    }
}
