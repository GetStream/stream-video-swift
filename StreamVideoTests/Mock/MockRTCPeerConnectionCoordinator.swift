//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnectionCoordinator: RTCPeerConnectionCoordinator, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    enum MockFunctionKey: Hashable, CaseIterable {
        case changePublishQuality
    }

    enum MockFunctionInputKey: Payloadable {
        case changePublishQuality(activeEncodings: Set<String>)
        var payload: Any {
            switch self {
            case let .changePublishQuality(activeEncodings):
                return activeEncodings
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
}
