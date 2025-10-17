//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension CurrentDevice {
    static func dummy(
        currentDeviceProvider: @MainActor @escaping @Sendable () -> DeviceType
    ) -> CurrentDevice {
        .init(currentDeviceProvider: currentDeviceProvider)
    }
}
