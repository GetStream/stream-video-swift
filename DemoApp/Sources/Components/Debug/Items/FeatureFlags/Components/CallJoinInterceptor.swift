//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

extension AppEnvironment {

    /// Debug-only toggle for enabling the new capturing pipeline path.
    enum CallJoinInterceptor: Hashable, Debuggable {
        case none, synchronised

        var title: String {
            switch self {
            case .none:
                return "None"
            case .synchronised:
                return "Synchronised"
            }
        }

        @MainActor
        var value: CallJoinIntercepting? {
            switch self {
            case .none:
                return nil
            case .synchronised:
                return DemoCallJoinInterceptor()
            }
        }
    }

    /// Default to enabled in debug builds so the pipeline is exercised during development.
    nonisolated(unsafe) static var callJoinInterceptor: CallJoinInterceptor = .none
}

extension DebugMenu {

    struct CallJoinInterceptorSelector: View {

        @State private var value = AppEnvironment.callJoinInterceptor {
            didSet { AppEnvironment.callJoinInterceptor = value }
        }

        var body: some View {
            ItemMenuView(
                items: [.none, .synchronised],
                currentValue: value,
                label: "Call Join Interceptor",
                availableAfterLogin: true,
                updater: { value = $0 }
            )
        }
    }
}
