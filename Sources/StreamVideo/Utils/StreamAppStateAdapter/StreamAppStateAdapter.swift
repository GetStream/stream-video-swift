//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif
import StreamCore

/// An adapter that observes the app's state and publishes changes.
public final class StreamAppStateAdapter: ObservableObject, @unchecked Sendable {

    /// Represents the app's state: foreground or background.
    public enum State: Sendable, Equatable { case foreground, background }

    /// The current state of the app.
    @Published public private(set) var state: State = .foreground

    private let notificationCenter: NotificationCenter
    private let disposableBag = DisposableBag()

    /// Initializes the adapter with a notification center.
    /// - Parameter notificationCenter: The notification center to use.
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        setUp()
    }

    // MARK: - Private Helpers

    /// Sets up observers for app state changes.
    private func setUp() {
        #if canImport(UIKit)
        Task { @MainActor in
            /// Observes app state changes to update the `state` property.
            notificationCenter
                .publisher(for: UIApplication.willEnterForegroundNotification)
                .map { _ in State.foreground }
                .receive(on: DispatchQueue.main)
                .assign(to: \.state, onWeak: self)
                .store(in: disposableBag)

            notificationCenter
                .publisher(for: UIApplication.didEnterBackgroundNotification)
                .map { _ in State.background }
                .receive(on: DispatchQueue.main)
                .assign(to: \.state, onWeak: self)
                .store(in: disposableBag)

            log.debug("\(type(of: self)) now observes application lifecycle.")
        }
        #endif
    }
}

extension StreamAppStateAdapter: InjectionKey {
    nonisolated(unsafe) public static var currentValue: StreamAppStateAdapter = .init()
}

extension InjectedValues {
    public var applicationStateAdapter: StreamAppStateAdapter {
        get {
            Self[StreamAppStateAdapter.self]
        }
        set {
            Self[StreamAppStateAdapter.self] = newValue
        }
    }
}
