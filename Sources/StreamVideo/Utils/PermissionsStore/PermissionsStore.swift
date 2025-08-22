//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import UserNotifications

public final class PermissionStore: ObservableObject, @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore

    @Published public private(set) var hasMicrophonePermission: Bool = false
    @Published public private(set) var hasCameraPermission: Bool = false

    private let store = Namespace.store(initialState: .initial)
    private let disposableBag = DisposableBag()

    private static let shared = PermissionStore()

    private init() {
        store
            .publisher(\.microphonePermission)
            .map { $0 == .granted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasMicrophonePermission, on: self)
            .store(in: disposableBag)

        store
            .publisher(\.cameraPermission)
            .map { $0 == .granted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasCameraPermission, on: self)
            .store(in: disposableBag)

        $hasMicrophonePermission
            .sink { [weak self] in self?.audioStore.dispatch(.audioSession(.setHasRecordingPermission($0))) }
            .store(in: disposableBag)
    }

    public func requestMicrophonePermission() async throws -> Bool {
        store.dispatch(.requestMicrophonePermission)
        return try await store.publisher(\.microphonePermission)
            .filter { $0 != .requesting && $0 != .unknown }
            .nextValue() == .granted
    }

    public func requestCameraPermission() async throws -> Bool {
        store.dispatch(.requestCameraPermission)
        return try await store.publisher(\.cameraPermission)
            .filter { $0 != .requesting && $0 != .unknown }
            .nextValue() == .granted
    }

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
