//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import UserNotifications

final class MockPushNotificationsPermissionProvider: PushNotificationsPermissionProviding, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockPushNotificationsPermissionProvider, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case requestPermission
        case systemPermission
    }

    enum MockFunctionInputKey: Payloadable {
        case requestPermission(options: UNAuthorizationOptions)
        case systemPermission

        var payload: Any {
            switch self {
            case let .requestPermission(options):
                return options
            case .systemPermission:
                return ()
            }
        }
    }

    init() {
        stub(for: .systemPermission, with: PermissionStore.Permission.unknown)
        stub(for: .requestPermission, with: false)
    }

    // MARK: - PushNotificationsPermissionProviding

    func systemPermission() async -> PermissionStore.Permission {
        stubbedFunctionInput[.systemPermission]?.append(.systemPermission)
        return stubbedFunction[.systemPermission] as! PermissionStore.Permission
    }

    func requestPermission(
        with options: UNAuthorizationOptions,
        _ completion: @escaping (Bool, Error?) -> Void
    ) {
        stubbedFunctionInput[.requestPermission]?
            .append(.requestPermission(options: options))

        if let stubbedResult = stubbedFunction[.requestPermission] as? Bool {
            completion(stubbedResult, nil)
        } else if let stubbedResult = stubbedFunction[.requestPermission] as? Error {
            completion(false, stubbedResult)
        } else {
            completion(false, ClientError())
        }
    }
}
