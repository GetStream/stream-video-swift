//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC

final class MockLocalMediaAdapter: LocalMediaAdapting, Mockable {
    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockLocalMediaAdapter, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case setUp
        case didUpdateCallSettings
        case publish
        case unpublish
    }

    enum MockFunctionInputKey: Payloadable {
        case setUp(settings: CallSettings, ownCapabilities: [OwnCapability])
        case didUpdateCallSettings(settings: CallSettings)
        case publish
        case unpublish

        var payload: Any {
            switch self {
            case let .setUp(settings, ownCapabilities):
                return (settings, ownCapabilities)
            case let .didUpdateCallSettings(settings):
                return settings
            case .publish:
                return ()
            case .unpublish:
                return ()
            }
        }
    }

    var subject: PassthroughSubject<TrackEvent, Never> = .init()

    func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        stubbedFunctionInput[.setUp]?
            .append(.setUp(settings: settings, ownCapabilities: ownCapabilities))
    }

    func publish() {
        stubbedFunctionInput[.publish]?
            .append(.publish)
    }

    func unpublish() {
        stubbedFunctionInput[.unpublish]?
            .append(.unpublish)
    }

    func didUpdateCallSettings(_ settings: CallSettings) async throws {
        stubbedFunctionInput[.didUpdateCallSettings]?
            .append(.didUpdateCallSettings(settings: settings))
    }
}
