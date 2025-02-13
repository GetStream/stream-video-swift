//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

///
/// A class that determines the current device type by inspecting available iOS
/// or macOS APIs. It reports whether the device is a phone, pad, TV, CarPlay,
/// mac, vision, or unspecified.
///
/// This information can be used throughout the app to adjust layout and
/// functionality based on the user's device.
///
/// ```
/// let device = CurrentDevice.currentValue
/// if device.deviceType == .phone {
///     // Configure layouts for phone
/// }
/// ```
final class CurrentDevice: Sendable {

    /// An enumeration describing the type of device. Each case can guide UI
    /// or behavior adjustments. For example, `.phone` might use a phone layout.
    enum DeviceType {
        /// The type was not determined or is unknown.
        case unspecified
        /// The current device is an iPhone or iPod touch.
        case phone
        /// The current device is an iPad.
        case pad
        /// The current device is an Apple TV.
        case tv
        /// The current device is CarPlay.
        case carPlay
        /// The current device is a Mac.
        case mac
        /// The current device is Vision Pro.
        case vision
    }

    /// The identified `DeviceType` for the current environment.
    let deviceType: DeviceType

    /// Creates a `CurrentDevice` by inspecting the user interface idiom.
    /// - Important: On platforms where UIKit is unavailable, the type defaults
    ///   to `.mac` (AppKit) or `.unspecified`.

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
    /// Retrieves the shared `CurrentDevice` instance. This can be used to query
    /// the device type at runtime.
    var currentDevice: CurrentDevice { Self[CurrentDevice.self] }
}
