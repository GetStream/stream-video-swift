//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// An enumeration representing device orientations: portrait or landscape.
public enum StreamDeviceOrientation: Equatable {
    case portrait(isUpsideDown: Bool)
    case landscape(isLeft: Bool)

    /// A computed property that indicates whether the orientation is portrait.
    public var isPortrait: Bool {
        switch self {
        case .landscape:
            return false
        case .portrait:
            return true
        }
    }

    /// A computed property that indicates whether the orientation is landscape.
    public var isLandscape: Bool {
        switch self {
        case .landscape:
            return true
        case .portrait:
            return false
        }
    }

    public var cgOrientation: CGImagePropertyOrientation {
        switch self {
        /// Handle known portrait orientations
        case let .portrait(isUpsideDown):
            return isUpsideDown ?.right : .left

        /// Handle known landscape orientations
        case let .landscape(isLeft):
            return isLeft ? .up : .down
        }
    }
}

/// An observable object that adapts to device orientation changes.
open class StreamDeviceOrientationAdapter: ObservableObject {
    public typealias Provider = () -> StreamDeviceOrientation

    /// The default provider for device orientation based on platform.
    @MainActor
    public static let defaultProvider: Provider = {
        #if canImport(UIKit)
        if let window = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            switch window.interfaceOrientation {
            case .unknown, .portrait:
                return .portrait(isUpsideDown: false)
            case .portraitUpsideDown:
                return .portrait(isUpsideDown: true)
            case .landscapeLeft:
                return .landscape(isLeft: true)
            case .landscapeRight:
                return .landscape(isLeft: false)
            @unknown default:
                return .portrait(isUpsideDown: false)
            }
        } else {
            return .portrait(isUpsideDown: false)
        }
        #else
        return .portrait(isUpsideDown: false)
        #endif
    }

    private var provider: Provider
    private var notificationCancellable: AnyCancellable?
    private var __cancelable: AnyCancellable?

    /// The current orientation observed by the adapter.
    @Published public private(set) var orientation: StreamDeviceOrientation = .portrait(isUpsideDown: false)

    /// Initializes an adapter for observing device orientation changes.
    /// - Parameters:
    ///   - notificationCenter: The notification center to observe orientation changes.
    ///   - provider: A custom provider for determining device orientation.
    @MainActor
    public init(
        notificationCenter: NotificationCenter = .default,
        _ provider: @escaping Provider = StreamDeviceOrientationAdapter.defaultProvider
    ) {
        self.provider = provider

        #if canImport(UIKit)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        // Subscribe to orientation change notifications on UIKit platforms.
        notificationCancellable = notificationCenter
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.orientation = provider() // Update orientation based on the provider.
            }
        #endif

        orientation = provider()
    }

    /// Cleans up resources when the adapter is deallocated.
    deinit {
        notificationCancellable?.cancel() // Cancel notification subscription.
        #if canImport(UIKit)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        #endif
    }
}

/// Provides the default value of the `StreamPictureInPictureAdapter` class.
enum StreamDeviceOrientationAdapterKey: InjectionKey {
    @MainActor
    static var currentValue: StreamDeviceOrientationAdapter = .init()
}

extension InjectedValues {
    /// Provides access to the `StreamDeviceOrientationAdapter` class to the views and view models.
    @MainActor
    public var orientationAdapter: StreamDeviceOrientationAdapter {
        get {
            Self[StreamDeviceOrientationAdapterKey.self]
        }
        set {
            Self[StreamDeviceOrientationAdapterKey.self] = newValue
        }
    }
}
