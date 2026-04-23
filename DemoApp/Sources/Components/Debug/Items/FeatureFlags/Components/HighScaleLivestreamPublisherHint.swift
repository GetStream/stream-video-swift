//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension AppEnvironment {

    /// Controls whether demo joins send the publisher hint or omit it.
    enum HighScaleLivestreamPublisherHintToggle: Hashable, Debuggable {
        case enabled, disabled

        /// Label consumed by the shared debug menu renderer.
        var title: String {
            switch self {
            case .enabled:
                return "Enabled"
            case .disabled:
                return "Disabled"
            }
        }

        /// `nil` omits the hint, which keeps regular demo joins unchanged.
        var value: Bool? {
            switch self {
            case .enabled:
                return true
            case .disabled:
                return nil
            }
        }
    }

    /// Omitting by default keeps regular demo joins on the standard path.
    nonisolated(unsafe) static var highScaleLivestreamPublisherHint:
        HighScaleLivestreamPublisherHintToggle = .disabled
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
