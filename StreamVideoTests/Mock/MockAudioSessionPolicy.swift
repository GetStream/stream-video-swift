//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockAudioSessionPolicy: Mockable, AudioSessionPolicy, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockAudioSessionPolicy, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case configuration
    }

    enum MockFunctionInputKey: Payloadable {
        case configuration(callSettings: CallSettings, ownCapabilities: Set<OwnCapability>)

        var payload: Any {
            switch self {
            case let .configuration(callSettings, ownCapabilities):
                return (callSettings, ownCapabilities)
            }
        }
    }

    // MARK: - AudioSessionPolicy

    init() {
        stub(
            for: .configuration,
            with: AudioSessionConfiguration(
                isActive: true,
                category: .soloAmbient,
                mode: .default,
                options: []
            )
        )
    }

    func configuration(
        for callSettings: CallSettings,
        ownCapabilities: Set<OwnCapability>
    ) -> AudioSessionConfiguration {
        stubbedFunctionInput[.configuration]?
            .append(
                .configuration(
                    callSettings: callSettings,
                    ownCapabilities: ownCapabilities
                )
            )
        return stubbedFunction[.configuration] as! AudioSessionConfiguration
    }
}
