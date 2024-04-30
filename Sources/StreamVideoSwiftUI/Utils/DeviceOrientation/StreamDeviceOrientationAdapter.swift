//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
#if canImport(UIKit)
import UIKit
#endif

/// An enumeration representing device orientations: portrait or landscape.
public enum StreamDeviceOrientation: Equatable {
    case portrait, landscape

    /// A computed property that indicates whether the orientation is portrait.
    public var isPortrait: Bool { self == .portrait }

    /// A computed property that indicates whether the orientation is landscape.
    public var isLandscape: Bool { self == .landscape }
}

/// An observable object that adapts to device orientation changes.
open class StreamDeviceOrientationAdapter: ObservableObject {
    public typealias Provider = () -> StreamDeviceOrientation

    /// The default provider for device orientation based on platform.
    public static let defaultProvider: Provider = {
        #if canImport(UIKit)
        switch UIDevice.current.orientation {
        case .unknown, .portrait, .portraitUpsideDown:
            return .portrait
        case .landscapeLeft, .landscapeRight:
            return .landscape
        case .faceUp, .faceDown:
            return .portrait
        @unknown default:
            return .portrait
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
