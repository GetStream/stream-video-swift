//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockCameraPermissionProvider: CameraPermissionProviding, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockCameraPermissionProvider, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case requestPermission
    }

    enum MockFunctionInputKey: Payloadable {
        case requestPermission

        var payload: Any {
            switch self {
            case .requestPermission:
                return ()
            }
        }
    }

    init() {
        stub(for: \.systemPermission, with: .unknown)
        stub(for: .requestPermission, with: false)
    }

    // MARK: - MicrophonePermissionProviding

    var systemPermission: PermissionStore.Permission {
        let value = stubbedProperty[propertyKey(for: \.systemPermission)]
        return value as! PermissionStore.Permission
    }

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        stubbedFunctionInput[.requestPermission]?.append(.requestPermission)
        if let stubbedResult = stubbedFunction[.requestPermission] as? Bool {
            completion(stubbedResult)
        } else {
            completion(false)
        }
    }
}
