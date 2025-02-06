//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

final class CurrentDevice {
    enum DeviceType { case unspecified, phone, pad, tv, carPlay, mac, vision }

    let deviceType: DeviceType

    private init() {
        #if canImport(UIKit)
        deviceType = switch UIDevice.current.userInterfaceIdiom {
        case .unspecified: .unspecified
        case .phone: .phone
        case .pad: .pad
        case .tv: .tv
        case .carPlay: .carPlay
        case .mac: .mac
        case .vision: .vision
        @unknown default: .unspecified
        }
        #elseif canImport(AppKit)
        deviceType = .mac
        #else
        deviceType = .unspecified
        #endif
    }
}

extension CurrentDevice: InjectionKey {
    static var currentValue: CurrentDevice = .init()
}

extension InjectedValues {
    var currentDevice: CurrentDevice { Self[CurrentDevice.self] }
}
