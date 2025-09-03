//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

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

    init(store: Store<Namespace> = Namespace.store(initialState: .initial)) {
        self.store = store
        canRequestMicrophonePermission = store.state.microphonePermission == .unknown
        hasMicrophonePermission = store.state.microphonePermission == .granted

        canRequestCameraPermission = store.state.cameraPermission == .unknown
        hasCameraPermission = store.state.cameraPermission == .granted

        store
            .publisher(\.microphonePermission)
            .map { $0 == .unknown || $0 == .requesting }
            .receive(on: DispatchQueue.main)
            .assign(to: \.canRequestMicrophonePermission, onWeak: self)
            .store(in: disposableBag)

        store
            .publisher(\.microphonePermission)
            .map { $0 == .granted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasMicrophonePermission, onWeak: self)
            .store(in: disposableBag)

        store
            .publisher(\.cameraPermission)
            .map { $0 == .unknown || $0 == .requesting }
            .receive(on: DispatchQueue.main)
            .assign(to: \.canRequestCameraPermission, onWeak: self)
            .store(in: disposableBag)

        store
            .publisher(\.cameraPermission)
            .map { $0 == .granted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasCameraPermission, onWeak: self)
            .store(in: disposableBag)

        if store.state.microphonePermission != .granted {
            $hasMicrophonePermission
                .removeDuplicates()
                .sink { [weak self] in
                    self?.audioStore.dispatch(.audioSession(.setHasRecordingPermission($0)))
                    if $0 {
                        self?.disposableBag.remove("observer")
                    }
                }
                .store(in: disposableBag, key: "observer")
        } else {
            audioStore.dispatch(.audioSession(.setHasRecordingPermission(true)))
        }
    }

    /// Requests microphone permission from the user.
    /// - Returns: `true` if permission was granted, `false` otherwise.
    /// - Throws: An error if the permission request times out.
    public func requestMicrophonePermission(
        file: StaticString = #fileID,
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
        file: StaticString = #fileID,
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
        file: StaticString = #fileID,
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

    // MARK: - Private helpers

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
    nonisolated(unsafe) public static var currentValue: PermissionStore = .shared
}

extension InjectedValues {
    public var permissions: PermissionStore {
        get { Self[PermissionStore.self] }
        set { Self[PermissionStore.self] = newValue }
    }
}
