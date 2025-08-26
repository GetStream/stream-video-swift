//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import UserNotifications

public final class PermissionStore: ObservableObject, @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore

    @Published public private(set) var hasMicrophonePermission: Bool
    @Published public private(set) var hasCameraPermission: Bool

    private let store: Store<Namespace>
    private let disposableBag = DisposableBag()

    static let shared = PermissionStore()

    init(store: Store<Namespace> = Namespace.store(initialState: .initial)) {
        self.store = store
        hasMicrophonePermission = store.state.microphonePermission == .granted
        hasCameraPermission = store.state.cameraPermission == .granted
        
        store
            .publisher(\.microphonePermission)
            .map { $0 == .granted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasMicrophonePermission, onWeak: self)
            .store(in: disposableBag)

        store
            .publisher(\.cameraPermission)
            .map { $0 == .granted }
            .receive(on: DispatchQueue.main)
            .assign(to: \.hasCameraPermission, onWeak: self)
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
