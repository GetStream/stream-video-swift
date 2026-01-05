//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockWebRTCPermissionsAdapterDelegate: WebRTCPermissionsAdapterDelegate, Mockable, @unchecked Sendable {

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case audioOn
        case videoOn
    }

    enum MockFunctionInputKey: Payloadable {
        case audioOn(Bool)
        case videoOn(Bool)

        var payload: Any {
            switch self {
            case let .audioOn(value):
                return value
            case let .videoOn(value):
                return value
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] =
        MockFunctionKey.allCases.reduce(into: [:]) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockWebRTCPermissionsAdapterDelegate, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    func permissionsAdapter(
        _ permissionsAdapter: WebRTCPermissionsAdapter,
        audioOn: Bool
    ) {
        stubbedFunctionInput[.audioOn]?.append(.audioOn(audioOn))
    }

    func permissionsAdapter(
        _ permissionsAdapter: WebRTCPermissionsAdapter,
        videoOn: Bool
    ) {
        stubbedFunctionInput[.videoOn]?.append(.videoOn(videoOn))
    }

    // Convenience accessors
    var audioOnValues: [Bool] {
        recordedInputPayload(Bool.self, for: .audioOn) ?? []
    }

    var videoOnValues: [Bool] {
        recordedInputPayload(Bool.self, for: .videoOn) ?? []
    }
}
