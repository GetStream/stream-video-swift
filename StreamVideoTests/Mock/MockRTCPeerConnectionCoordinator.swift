//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnectionCoordinator:
    RTCPeerConnectionCoordinator,
    Mockable,
    @unchecked Sendable
{

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    enum MockFunctionKey: Hashable, CaseIterable {
        case changePublishQuality
        case didUpdateCallSettings
        case mid
        case localTrack
        case restartICE
        case close
    }

    enum MockFunctionInputKey: Payloadable {
        case changePublishQuality(activeEncodings: Set<String>)
        case didUpdateCallSettings(callSettings: CallSettings)
        case mid(type: TrackType)
        case localTrack(type: TrackType)
        case restartICE
        case close

        var payload: Any {
            switch self {
            case let .changePublishQuality(activeEncodings):
                return activeEncodings
            case let .didUpdateCallSettings(callSettings):
                return callSettings
            case let .mid(type):
                return type
            case let .localTrack(type):
                return type
            case .restartICE:
                return ()
            case .close:
                return ()
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockRTCPeerConnectionCoordinator, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - Overrides

    override var disconnectedPublisher: AnyPublisher<Void, Never> {
        if let stub = stubbedProperty[propertyKey(for: \.disconnectedPublisher)] as? AnyPublisher<Void, Never> {
            return stub
        } else {
            return super.disconnectedPublisher
        }
    }

    convenience init?(
        sessionId: String = .unique,
        peerType: PeerConnectionType,
        videoOptions: VideoOptions = .init(),
        videoConfig: VideoConfig = .dummy(),
        callSettings: CallSettings = .init(),
        audioSettings: AudioSettings = .init(),
        sfuAdapter: SFUAdapter,
        audioSession: AudioSession = .init(),
        screenShareSessionProvider: ScreenShareSessionProvider = .init()
    ) throws {
        let peerConnectionFactory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule()
        )
        self.init(
            sessionId: .unique,
            peerType: peerType,
            peerConnection: MockRTCPeerConnection(),
            peerConnectionFactory: peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            sfuAdapter: sfuAdapter,
            audioSession: audioSession,
            screenShareSessionProvider: screenShareSessionProvider
        )
    }

    override func changePublishQuality(with activeEncodings: Set<String>) {
        stubbedFunctionInput[.changePublishQuality]?
            .append(.changePublishQuality(activeEncodings: activeEncodings))
    }

    override func didUpdateCallSettings(_ settings: CallSettings) async throws {
        stubbedFunctionInput[.didUpdateCallSettings]?
            .append(.didUpdateCallSettings(callSettings: settings))

        if let result = stubbedFunction[.didUpdateCallSettings] as? Result<Void, Error> {
            switch result {
            case .success:
                break
            case let .failure(error):
                throw error
            }
        }
    }

    override func mid(for type: TrackType) -> String? {
        stubbedFunctionInput[.mid]?.append(.mid(type: type))
        return stubbedFunction[.mid] as? String
    }

    override func localTrack(of type: TrackType) -> RTCMediaStreamTrack? {
        stubbedFunctionInput[.localTrack]?.append(.mid(type: type))
        return stubbedFunction[.localTrack] as? RTCMediaStreamTrack
    }

    override func restartICE() {
        stubbedFunctionInput[.restartICE]?.append(.restartICE)
    }

    override func close() {
        stubbedFunctionInput[.close]?.append(.close)
    }
}
