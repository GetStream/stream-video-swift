//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// swiftlint:disable discourage_task_init

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation

/// An enumeration representing device orientations: portrait or landscape.
public enum StreamDeviceOrientation: Equatable, Sendable {
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

    #if canImport(UIKit)
    public var deviceOrientation: UIDeviceOrientation {
        switch self {
        case let .portrait(isUpsideDown):
            return isUpsideDown ? .portraitUpsideDown : .portrait
        case let .landscape(isLeft):
            return isLeft ? .landscapeLeft : .landscapeRight
        }
    }
    #endif

    public var captureVideoOrientation: AVCaptureVideoOrientation {
        switch self {
        case let .portrait(isUpsideDown):
            return isUpsideDown ? .portraitUpsideDown : .portrait
        case let .landscape(isLeft):
            return isLeft ? .landscapeLeft : .landscapeRight
        }
    }
}

/// An observable object that adapts to device orientation changes.
open class StreamDeviceOrientationAdapter: ObservableObject, @unchecked Sendable {
    public typealias Provider = @Sendable () async -> StreamDeviceOrientation

    /// The default provider for device orientation based on platform.
    public static let defaultProvider: Provider = {
        #if canImport(UIKit)
        await Task { @MainActor in
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
        }.value
        #else
        return .portrait(isUpsideDown: false)
        #endif
    }

    private var provider: Provider
    private let disposableBag = DisposableBag()

    /// The current orientation observed by the adapter.
    @Published public private(set) var orientation: StreamDeviceOrientation = .portrait(isUpsideDown: false)

    /// Initializes an adapter for observing device orientation changes.
    /// - Parameters:
    ///   - notificationCenter: The notification center to observe orientation changes.
    ///   - provider: A custom provider for determining device orientation.
    public init(
        notificationCenter: NotificationCenter = .default,
        _ provider: @escaping Provider = StreamDeviceOrientationAdapter.defaultProvider
    ) {
        self.provider = provider

        #if canImport(UIKit)
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else { return }
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            // Subscribe to orientation change notifications on UIKit platforms.
            notificationCenter
                .publisher(for: UIDevice.orientationDidChangeNotification)
                .map { _ in }
                .receive(on: DispatchQueue.main)
                .sinkTask(storeIn: disposableBag) { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.orientation = await provider() // Update orientation based on the provider.
                }
                .store(in: disposableBag)

            self.orientation = await provider()
        }
        #endif
    }

    /// Cleans up resources when the adapter is deallocated.
    deinit {
        disposableBag.removeAll()
        #if canImport(UIKit)
        Task { @MainActor in
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        #endif
    }
}

/// Provides the default value of the `StreamPictureInPictureAdapter` class.
enum StreamDeviceOrientationAdapterKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamDeviceOrientationAdapter = .init()
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
