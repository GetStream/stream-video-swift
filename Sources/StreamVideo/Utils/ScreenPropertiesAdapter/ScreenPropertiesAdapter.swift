//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import StreamCore

final class ScreenPropertiesAdapter: @unchecked Sendable {

    private(set) var preferredFramesPerSecond: Int = 0
    private(set) var refreshRate: TimeInterval = 0
    private(set) var scale: CGFloat = 0

    init() {
        Task { @MainActor in
            let maximumFramesPerSecond: Int
            #if canImport(UIKit)
            maximumFramesPerSecond = max(30, UIScreen.main.maximumFramesPerSecond)
            #else
            maximumFramesPerSecond = 30
            #endif
            preferredFramesPerSecond = maximumFramesPerSecond
            refreshRate = 1.0 / Double(maximumFramesPerSecond)
            scale = UIScreen.main.scale
        }
    }
}

extension ScreenPropertiesAdapter: InjectionKey {
    nonisolated(unsafe) static var currentValue: ScreenPropertiesAdapter = .init()
}

extension InjectedValues {
    var screenProperties: ScreenPropertiesAdapter {
        set { Self[ScreenPropertiesAdapter.self] = newValue }
        get { Self[ScreenPropertiesAdapter.self] }
    }
}
