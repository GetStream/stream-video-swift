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
            .sink { [weak self] in self?.audioStore.dispatch(.audioSession(.setHasRecordingPermission($0))) }
            .store(in: disposableBag)
    }

    /// Requests microphone permission from the user.
    /// - Returns: `true` if permission was granted, `false` otherwise.
    /// - Throws: An error if the permission request times out.
    public func requestMicrophonePermission() async throws -> Bool {
        store.dispatch(.requestMicrophonePermission)
        return try await store.publisher(\.microphonePermission)
            .filter { $0 != .requesting && $0 != .unknown }
            .nextValue() == .granted
    }

    /// Requests camera permission from the user.
    /// - Returns: `true` if permission was granted, `false` otherwise.
    /// - Throws: An error if the permission request times out.
    public func requestCameraPermission() async throws -> Bool {
        store.dispatch(.requestCameraPermission)
        return try await store.publisher(\.cameraPermission)
            .filter { $0 != .requesting && $0 != .unknown }
            .nextValue() == .granted
    }

    /// Requests push notification permission from the user.
    /// - Parameter options: The notification authorization options to request.
    /// - Returns: `true` if permission was granted, `false` otherwise.
    /// - Throws: An error if the permission request times out.
    public func requestPushNotificationPermission(
        with options: UNAuthorizationOptions
    ) async throws -> Bool {
        store.dispatch(.requestPushNotificationPermission(options))
        return try await store.publisher(\.pushNotificationPermission)
            .filter { $0 != .requesting && $0 != .unknown }
            .nextValue() == .granted
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
