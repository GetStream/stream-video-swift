//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import UserNotifications

/// Manages system permissions for camera, microphone, and push notifications.
/// Provides a reactive interface for permission state observation and requests.
public final class PermissionStore: ObservableObject, @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore

    @Published public private(set) var canRequestMicrophonePermission: Bool
    @Published public private(set) var hasMicrophonePermission: Bool

    @Published public private(set) var canRequestCameraPermission: Bool
    @Published public private(set) var hasCameraPermission: Bool

    private let store: Store<Namespace>
    private let disposableBag = DisposableBag()

    static let shared = PermissionStore()

    var state: Namespace.State { store.state }

    init(store: Store<Namespace> = Namespace.store(initialState: .initial)) {
        self.store = store
        canRequestMicrophonePermission = store.state.microphonePermission == .unknown || store.state
            .microphonePermission == .requesting
        hasMicrophonePermission = store.state.microphonePermission == .granted
        canRequestCameraPermission = store.state.cameraPermission == .unknown || store.state.cameraPermission == .requesting
        hasCameraPermission = store.state.cameraPermission == .granted

        store
            .publisher(\.microphonePermission)
            .filter { $0 != .requesting }
            .map { $0 == .unknown }
            .receive(on: DispatchQueue.main)
            .assign(to: \.canRequestMicrophonePermission, onWeak: self)
            .store(in: disposableBag)

        store
            .publisher(\.microphonePermission)
            .filter { $0 != .requesting }
            .map { $0 == .granted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasMicrophonePermission, onWeak: self)
            .store(in: disposableBag)

        store
            .publisher(\.cameraPermission)
            .filter { $0 != .requesting }
            .map { $0 == .unknown }
            .receive(on: DispatchQueue.main)
            .assign(to: \.canRequestCameraPermission, onWeak: self)
            .store(in: disposableBag)

        store
            .publisher(\.cameraPermission)
            .filter { $0 != .requesting }
            .map { $0 == .granted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasCameraPermission, onWeak: self)
            .store(in: disposableBag)

        $hasMicrophonePermission
            .removeDuplicates()
            .sink { [weak self] in
                self?.audioStore.dispatch(.setHasRecordingPermission($0))
            }
            .store(in: disposableBag)
    }

    /// Requests microphone permission from the user.
    /// - Returns: `true` if permission was granted, `false` otherwise.
    /// - Throws: An error if the permission request times out.
    public func requestMicrophonePermission(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws -> Bool {
        try await processAccessRequest(
            keyPath: \.microphonePermission,
            requestAction: .requestMicrophonePermission,
            file: file,
            function: function,
            line: line
        )
    }

    /// Requests camera permission from the user.
    /// - Returns: `true` if permission was granted, `false` otherwise.
    /// - Throws: An error if the permission request times out.
    public func requestCameraPermission(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws -> Bool {
        try await processAccessRequest(
            keyPath: \.cameraPermission,
            requestAction: .requestCameraPermission,
            file: file,
            function: function,
            line: line
        )
    }

    /// Requests push notification permission from the user.
    /// - Parameter options: The notification authorization options to request.
    /// - Returns: `true` if permission was granted, `false` otherwise.
    /// - Throws: An error if the permission request times out.
    public func requestPushNotificationPermission(
        with options: UNAuthorizationOptions,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws -> Bool {
        try await processAccessRequest(
            keyPath: \.pushNotificationPermission,
            requestAction: .requestPushNotificationPermission(options),
            file: file,
            function: function,
            line: line
        )
    }

    // MARK: - Private Helpers

    private func processAccessRequest(
        keyPath: KeyPath<Namespace.State, Permission>,
        requestAction: Namespace.Action,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> Bool {
        switch store.state[keyPath: keyPath] {
        case .unknown:
            log.debug(
                "Store identifier:\(Namespace.identifier) requesting permission for keyPath:\(keyPath).",
                functionName: function,
                fileName: file,
                lineNumber: line
            )
            store.dispatch(requestAction)

            let result = try await store.publisher(keyPath)
                .receive(on: DispatchQueue.main)
                .filter { $0 != .requesting && $0 != .unknown }
                .nextValue() == .granted

            log.debug(
                "Store identifier:\(Namespace.identifier) permission request for keyPath:\(keyPath) completed with grant result:\(result).",
                functionName: function,
                fileName: file,
                lineNumber: line
            )
            return result

        case .requesting:
            let result = try await store.publisher(keyPath)
                .receive(on: DispatchQueue.main)
                .filter { $0 != .requesting && $0 != .unknown }
                .nextValue() == .granted

            log.debug(
                "Store identifier:\(Namespace.identifier) permission request for keyPath:\(keyPath) completed with grant result:\(result).",
                functionName: function,
                fileName: file,
                lineNumber: line
            )
            return result

        case .granted:
            return true

        case .denied:
            return false
        }
    }
}

extension PermissionStore: InjectionKey {
    public nonisolated(unsafe) static var currentValue: PermissionStore = .shared
}

extension InjectedValues {
    public var permissions: PermissionStore {
        get { Self[PermissionStore.self] }
        set { Self[PermissionStore.self] = newValue }
    }
}
