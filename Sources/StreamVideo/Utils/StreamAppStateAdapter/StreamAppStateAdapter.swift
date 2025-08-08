//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif

public protocol AppStateProviding: Sendable {
    var state: ApplicationState { get }

    var statePublisher: AnyPublisher<ApplicationState, Never> { get }
}

/// Represents the app's state: foreground or background.
public enum ApplicationState: String, Sendable, Equatable { case unknown, foreground, background }

/// An adapter that observes the app's state and publishes changes.
final class StreamAppStateAdapter: AppStateProviding, ObservableObject, @unchecked Sendable {

    /// The current state of the app.
    @Published public private(set) var state: ApplicationState = .unknown
    var statePublisher: AnyPublisher<ApplicationState, Never> { $state.eraseToAnyPublisher() }

    private let notificationCenter: NotificationCenter
    private let disposableBag = DisposableBag()

    /// Initializes the adapter with a notification center.
    /// - Parameter notificationCenter: The notification center to use.
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        setUp()

        statePublisher
            .removeDuplicates()
            .log(.debug) { "Application state changed to \($0)" }
            .sink { _ in }
            .store(in: disposableBag)
    }

    // MARK: - Private Helpers

    /// Sets up observers for app state changes.
    private func setUp() {
        #if canImport(UIKit)
        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else { return }
            /// Observes app state changes to update the `state` property.
            notificationCenter
                .publisher(for: UIApplication.willEnterForegroundNotification)
                .map { _ in ApplicationState.foreground }
                .receive(on: DispatchQueue.main)
                .assign(to: \.state, onWeak: self)
                .store(in: disposableBag)

            notificationCenter
                .publisher(for: UIApplication.didBecomeActiveNotification)
                .map { _ in ApplicationState.foreground }
                .receive(on: DispatchQueue.main)
                .assign(to: \.state, onWeak: self)
                .store(in: disposableBag)

            notificationCenter
                .publisher(for: UIApplication.didEnterBackgroundNotification)
                .map { _ in ApplicationState.background }
                .receive(on: DispatchQueue.main)
                .assign(to: \.state, onWeak: self)
                .store(in: disposableBag)

            switch UIApplication.shared.applicationState {
            case .active:
                state = .foreground
            case .inactive:
                state = .unknown
            case .background:
                state = .background
            @unknown default:
                state = .unknown
            }

            log.debug("\(type(of: self)) now observes application lifecycle.")
        }
        #endif
    }
}

enum AppStateProviderKey: InjectionKey {
    nonisolated(unsafe) public static var currentValue: AppStateProviding = StreamAppStateAdapter()
}

extension InjectedValues {
    public var applicationStateAdapter: AppStateProviding {
        get {
            Self[AppStateProviderKey.self]
        }
        set {
            Self[AppStateProviderKey.self] = newValue
        }
    }
}
