//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class ScreenPropertiesAdapter: @unchecked Sendable {

    public private(set) var preferredFramesPerSecond: Int = 0
    public private(set) var refreshRate: TimeInterval = 0
    public private(set) var scale: CGFloat = 0

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
    public nonisolated(unsafe) static var currentValue: ScreenPropertiesAdapter = .init()
}

extension InjectedValues {
    public var screenProperties: ScreenPropertiesAdapter {
        set { Self[ScreenPropertiesAdapter.self] = newValue }
        get { Self[ScreenPropertiesAdapter.self] }
    }
}
