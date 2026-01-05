//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC

final class MockLocalMediaAdapter: LocalMediaAdapting, Mockable, @unchecked Sendable {

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
        case trackInfo
        case didUpdatePublishOptions
        case changePublishQuality
    }

    enum MockFunctionInputKey: Payloadable {
        case setUp(settings: CallSettings, ownCapabilities: [OwnCapability])
        case didUpdateCallSettings(settings: CallSettings)
        case publish
        case unpublish
        case trackInfo(collectionType: RTCPeerConnectionTrackInfoCollectionType)
        case didUpdatePublishOptions(publishOptions: PublishOptions)

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
            case let .trackInfo(collectionType):
                return collectionType
            case let .didUpdatePublishOptions(publishOptions):
                return publishOptions
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

    func trackInfo(for collectionType: RTCPeerConnectionTrackInfoCollectionType) -> [Stream_Video_Sfu_Models_TrackInfo] {
        stubbedFunctionInput[.trackInfo]?.append(.trackInfo(collectionType: collectionType))
        return stubbedFunction[.trackInfo] as? [Stream_Video_Sfu_Models_TrackInfo] ?? []
    }
    
    func didUpdatePublishOptions(_ publishOptions: PublishOptions) async throws {
        stubbedFunctionInput[.didUpdatePublishOptions]?
            .append(.didUpdatePublishOptions(publishOptions: publishOptions))
    }
}
