//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

final class ScreenPropertiesAdapter {

    let preferredFramesPerSecond: Int
    let refreshRate: TimeInterval

    init() {
        let maximumFramesPerSecond: Int
        #if canImport(UIKit)
        maximumFramesPerSecond = max(30, UIScreen.main.maximumFramesPerSecond)
        #else
        maximumFramesPerSecond = 30
        #endif
        preferredFramesPerSecond = maximumFramesPerSecond
        refreshRate = 1.0 / Double(maximumFramesPerSecond)
    }
}

extension ScreenPropertiesAdapter: InjectionKey {
    static var currentValue: ScreenPropertiesAdapter = .init()
}

extension InjectedValues {
    var screenProperties: ScreenPropertiesAdapter {
        set { Self[ScreenPropertiesAdapter.self] = newValue }
        get { Self[ScreenPropertiesAdapter.self] }
    }
}
