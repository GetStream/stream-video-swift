//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum StreamDeviceOrientation: Equatable {
    case portrait(isUpsideDown: Bool), landscape(isLeft: Bool)

    public var isPortrait: Bool {
        switch self {
        case .portrait:
            return true
        case .landscape:
            return false
        }
    }

    public var isLandscape: Bool {
        switch self {
        case .portrait:
            return false
        case .landscape:
            return true
        }
    }
}

open class StreamDeviceOrientationAdapter: ObservableObject {
    public typealias Provider = () -> StreamDeviceOrientation

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

    @Published public private(set) var orientation: StreamDeviceOrientation

    public init(
        notificationCenter: NotificationCenter = .default,
        _ provider: @escaping Provider = StreamDeviceOrientationAdapter.defaultProvider
    ) {
        self.provider = provider
        orientation = provider()

        #if canImport(UIKit)
        notificationCancellable = notificationCenter
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.orientation = provider()
            }
        #endif
    }

    deinit {
        notificationCancellable?.cancel()
    }
}

/// Provides the default value of the `StreamPictureInPictureAdapter` class.
public struct StreamDeviceOrientationAdapterKey: InjectionKey {
    public static var currentValue: StreamDeviceOrientationAdapter = .init()
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
