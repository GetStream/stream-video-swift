//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension AppEnvironment {

    /// Wraps a debug menu view in an identifiable container.
    struct FeatureFlag: Identifiable {
        var id: UUID = .init()
        var viewProvider: () -> AnyView
    }

    nonisolated(unsafe) static var featureFlags: [FeatureFlag] = [
        .init { .init(DebugMenu.VideoProcessingPipelineToggleView()) },
        .init { .init(DebugMenu.CapturingPipelineToggleView()) }
    ]
}

extension DebugMenu {

    /// Presents the registered feature-flag views inside the debug menu.
    struct FeatureFlagsView: View {

        private var items = AppEnvironment.featureFlags

        var body: some View {
            Menu {
                ForEach(items) { $0.viewProvider() }
            } label: {
                Label {
                    Text("Feature Flags")
                } icon: {
                    Image(systemName: "testtube.2")
                }
            }
        }
    }
}
