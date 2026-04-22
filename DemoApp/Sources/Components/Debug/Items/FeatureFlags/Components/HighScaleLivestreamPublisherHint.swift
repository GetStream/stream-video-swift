//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension AppEnvironment {

    enum HighScaleLivestreamPublisherHintToggle: Hashable, Debuggable {
        case enabled, disabled

        var title: String {
            switch self {
            case .enabled:
                return "Enabled"
            case .disabled:
                return "Disabled"
            }
        }

        var value: Bool? {
            switch self {
            case .enabled:
                return true
            case .disabled:
                return nil
            }
        }
    }

    nonisolated(unsafe) static var highScaleLivestreamPublisherHint: HighScaleLivestreamPublisherHintToggle = .disabled
}

extension DebugMenu {

    struct HighScaleLivestreamPublisherHintToggleView: View {

        @State private var value = AppEnvironment.highScaleLivestreamPublisherHint {
            didSet { AppEnvironment.highScaleLivestreamPublisherHint = value }
        }

        var body: some View {
            ItemMenuView(
                items: [.enabled, .disabled],
                currentValue: value,
                label: "High-Scale Livestream Hint",
                availableAfterLogin: true,
                updater: { value = $0 }
            )
        }
    }
}
