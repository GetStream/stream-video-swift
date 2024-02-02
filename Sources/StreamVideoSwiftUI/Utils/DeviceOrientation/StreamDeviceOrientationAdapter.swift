//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
#if canImport(UIKit)
import UIKit
#endif

public enum StreamDeviceOrientation: Equatable {
    case portrait, landscape

    public var isPortrait: Bool { self == .portrait }
    public var isLandscape: Bool { self == .landscape }
}

open class StreamDeviceOrientationAdapter: ObservableObject {
    public typealias Provider = () -> StreamDeviceOrientation

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
