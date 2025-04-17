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
public final class CurrentDevice: @unchecked Sendable {

    /// An enumeration describing the type of device. Each case can guide UI
    /// or behavior adjustments. For example, `.phone` might use a phone layout.
    public enum DeviceType: Sendable {
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
    public internal(set) var deviceType: DeviceType = .unspecified
    public internal(set) var systemVersion: String = "-"

    /// Creates a `CurrentDevice` by inspecting the user interface idiom.
    /// - Important: On platforms where UIKit is unavailable, the type defaults
    ///   to `.mac` (AppKit) or `.unspecified`.

    private init() {
        Task { @MainActor in
            self.systemVersion = UIDevice.current.systemVersion
            #if canImport(UIKit)
            self.deviceType = switch UIDevice.current.userInterfaceIdiom {
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
}

extension CurrentDevice: InjectionKey {
    public nonisolated(unsafe) static var currentValue: CurrentDevice = .init()
}

extension InjectedValues {
    /// Retrieves the shared `CurrentDevice` instance. This can be used to query
    /// the device type at runtime.
    public var currentDevice: CurrentDevice {
        get { Self[CurrentDevice.self] }
        set { _ = newValue }
    }
}
