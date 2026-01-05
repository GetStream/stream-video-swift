//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// swiftlint:disable discourage_task_init

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class ScreenPropertiesAdapter: @unchecked Sendable {

    public private(set) var preferredFramesPerSecond: Int = 30
    public private(set) var refreshRate: TimeInterval = 0.16
    public private(set) var scale: CGFloat = 1

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
