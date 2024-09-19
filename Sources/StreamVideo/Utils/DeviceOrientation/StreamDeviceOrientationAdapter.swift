//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    public static let defaultProvider: Provider = {
        #if canImport(UIKit)
        switch UIDevice.current.orientation {
        case .unknown, .portrait:
            return .portrait(isUpsideDown: false)
        case .portraitUpsideDown:
            return .portrait(isUpsideDown: true)
        case .landscapeLeft:
            return .landscape(isLeft: true)
        case .landscapeRight:
            return .landscape(isLeft: false)
        case .faceUp, .faceDown:
            return .portrait(isUpsideDown: false)
        @unknown default:
            return .portrait(isUpsideDown: false)
        }
        #else
        return .portrait
        #endif
    }

    private var provider: Provider
    private var notificationCancellable: AnyCancellable?

    /// The current orientation observed by the adapter.
    @Published public private(set) var orientation: StreamDeviceOrientation

    /// Initializes an adapter for observing device orientation changes.
    /// - Parameters:
    ///   - notificationCenter: The notification center to observe orientation changes.
    ///   - provider: A custom provider for determining device orientation.
    public init(
        notificationCenter: NotificationCenter = .default,
        _ provider: @escaping Provider = StreamDeviceOrientationAdapter.defaultProvider
    ) {
        self.provider = provider
        orientation = provider()

        #if canImport(UIKit)
        // Subscribe to orientation change notifications on UIKit platforms.
        notificationCancellable = notificationCenter
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.orientation = provider() // Update orientation based on the provider.
            }
        #endif
    }

    /// Cleans up resources when the adapter is deallocated.
    deinit {
        notificationCancellable?.cancel() // Cancel notification subscription.
    }
}

/// Provides the default value of the `StreamPictureInPictureAdapter` class.
enum StreamDeviceOrientationAdapterKey: InjectionKey {
    static var currentValue: StreamDeviceOrientationAdapter = .init()
}

extension InjectedValues {
    /// Provides access to the `StreamDeviceOrientationAdapter` class to the views and view models.
    public var orientationAdapter: StreamDeviceOrientationAdapter {
        get {
            Self[StreamDeviceOrientationAdapterKey.self]
        }
        set {
            Self[StreamDeviceOrientationAdapterKey.self] = newValue
        }
    }
}
