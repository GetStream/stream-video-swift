//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

extension Call_IntegrationTests.Helpers {
    final class StreamVideoHelper: @unchecked Sendable {
        static let videoConfig: VideoConfig = .dummy()
        enum ConnectMode { case none, onInit, afterInit }
        enum ClientRegisterMode { case none, auto, autoWithouSingletonUpdate }
        enum ClientResolutionMode { case `default`, ignoreCache }

        let videoConfig: VideoConfig
        let pushNotificationConfig: PushNotificationsConfig

        private var registeredClients: [String: StreamVideo] = [:]

        init(
            videoConfig: VideoConfig = StreamVideoHelper.videoConfig,
            pushNotificationConfig: PushNotificationsConfig = .default
        ) {
            self.videoConfig = videoConfig
            self.pushNotificationConfig = pushNotificationConfig
        }

        func dismantle() async {
            for client in registeredClients.values {
                await client.disconnect()
            }

            StreamVideoProviderKey.currentValue = nil

            registeredClients = [:]
        }

        func buildClient(
            apiKey: String,
            token: String,
            userId: String,
            connectMode: ConnectMode,
            clientResolutionMode: ClientResolutionMode,
            clientRegisterMode: ClientRegisterMode,
            streamVideoEnvironment: StreamVideo.Environment = .init()
        ) async throws -> StreamVideo {
            let autoConnectOnInit = {
                switch connectMode {
                case .none:
                    return false
                case .onInit:
                    return true
                case .afterInit:
                    return false
                }
            }()

            let currentStreamVideo = StreamVideoProviderKey.currentValue
            let result = {
                if clientResolutionMode == .default, let existingClient = registeredClients[userId] {
                    return existingClient
                } else {
                    return StreamVideo(
                        apiKey: apiKey,
                        user: User(id: userId),
                        token: .init(rawValue: token),
                        videoConfig: videoConfig,
                        tokenProvider: { _ in },
                        pushNotificationsConfig: pushNotificationConfig,
                        environment: streamVideoEnvironment,
                        autoConnectOnInit: autoConnectOnInit
                    )
                }
            }()

            if connectMode == .afterInit {
                try await result.connect()
            }

            switch clientRegisterMode {
            case .none:
                // Reassign the StreamVideo that was assigned before the
                // new instance gets created.
                StreamVideoProviderKey.currentValue = currentStreamVideo

            case .auto:
                StreamVideoProviderKey.currentValue = result
                registeredClients[userId] = result

            case .autoWithouSingletonUpdate:
                // Reassign the StreamVideo that was assigned before the
                // new instance gets created.
                StreamVideoProviderKey.currentValue = currentStreamVideo
                registeredClients[userId] = result
            }

            return result
        }

        func removeClient(
            for userId: String,
            disconnect: Bool
        ) async {
            guard let client = registeredClients[userId] else {
                return
            }

            if disconnect {
                await client.disconnect()
            }

            registeredClients[userId] = nil
        }

        func client(for userId: String) -> StreamVideo? {
            registeredClients[userId]
        }
    }
}

extension StreamVideo.Environment {
    static var silentAudioDevice: Self {
        var environment = Self()
        environment.callControllerBuilder = {
            defaultAPI,
                user,
                callId,
                callType,
                apiKey,
                videoConfig,
                initialCallSettings,
                cachedLocation in
            let peerConnectionFactory = PeerConnectionFactory.build(
                audioProcessingModule: videoConfig.audioProcessingModule,
                audioDeviceModuleSource: MockRTCAudioDeviceModule(),
                audioDevice: SilentAudioDevice()
            )
            return CallController(
                defaultAPI: defaultAPI,
                user: user,
                callId: callId,
                callType: callType,
                apiKey: apiKey,
                videoConfig: videoConfig,
                initialCallSettings: initialCallSettings,
                cachedLocation: cachedLocation,
                webRTCCoordinatorFactory: WebRTCCoordinatorFactory(
                    peerConnectionFactory: peerConnectionFactory
                )
            )
        }
        return environment
    }
}

private final class SilentAudioDevice: NSObject, RTCAudioDevice {
    let deviceInputSampleRate: Double = 48000
    let inputIOBufferDuration: TimeInterval = 0.01
    let inputNumberOfChannels: Int = 1
    let inputLatency: TimeInterval = 0
    let deviceOutputSampleRate: Double = 48000
    let outputIOBufferDuration: TimeInterval = 0.01
    let outputNumberOfChannels: Int = 1
    let outputLatency: TimeInterval = 0

    private(set) var isInitialized = false
    private(set) var isPlayoutInitialized = false
    private(set) var isPlaying = false
    private(set) var isRecordingInitialized = false
    private(set) var isRecording = false

    private var delegate: RTCAudioDeviceDelegate?

    func initialize(with delegate: RTCAudioDeviceDelegate) -> Bool {
        self.delegate = delegate
        isInitialized = true
        return true
    }

    func terminateDevice() -> Bool {
        delegate = nil
        isInitialized = false
        isPlayoutInitialized = false
        isPlaying = false
        isRecordingInitialized = false
        isRecording = false
        return true
    }

    func initializePlayout() -> Bool {
        isPlayoutInitialized = true
        return true
    }

    func startPlayout() -> Bool {
        isPlaying = true
        return true
    }

    func stopPlayout() -> Bool {
        isPlaying = false
        return true
    }

    func initializeRecording() -> Bool {
        isRecordingInitialized = true
        return true
    }

    func startRecording() -> Bool {
        isRecording = true
        return true
    }

    func stopRecording() -> Bool {
        isRecording = false
        return true
    }
}
