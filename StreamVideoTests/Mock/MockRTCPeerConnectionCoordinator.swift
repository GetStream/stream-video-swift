//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCPeerConnectionCoordinator:
    RTCPeerConnectionCoordinator,
    Mockable,
    @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    enum MockFunctionKey: Hashable, CaseIterable {
        case changePublishQuality
        case didUpdateCallSettings
        case mid
        case localTrack
        case restartICE
        case close
        case setVideoFilter
        case ensureSetUpHasBeenCompleted
        case setUp
        case beginScreenSharing
        case didUpdateCameraPosition
        case stopScreenSharing
        case focus
        case addCapturePhotoOutput
        case removeCapturePhotoOutput
        case addVideoOutput
        case removeVideoOutput
        case zoom
        case trackInfo
        case statsReport
        case setAudioMaxBitrate
    }

    enum MockFunctionInputKey: Payloadable {
        case changePublishQuality(event: Stream_Video_Sfu_Event_ChangePublishQuality)
        case didUpdateCallSettings(callSettings: CallSettings)
        case didUpdateCameraPosition(position: AVCaptureDevice.Position)
        case mid(type: TrackType)
        case localTrack(type: TrackType)
        case restartICE
        case close
        case setVideoFilter(videoFilter: VideoFilter?)
        case ensureSetUpHasBeenCompleted
        case setUp(settings: CallSettings, ownCapabilities: [OwnCapability])
        case beginScreenSharing(type: ScreensharingType, ownCapabilities: [OwnCapability], includeAudio: Bool)
        case stopScreenSharing
        case focus(point: CGPoint)
        case addCapturePhotoOutput(capturePhotoOutput: AVCapturePhotoOutput)
        case removeCapturePhotoOutput(capturePhotoOutput: AVCapturePhotoOutput)
        case addVideoOutput(videoOutput: AVCaptureVideoDataOutput)
        case removeVideoOutput(videoOutput: AVCaptureVideoDataOutput)
        case zoom(factor: CGFloat)
        case trackInfo(trackType: TrackType)
        case statsReport
        case setAudioMaxBitrate(AudioBitrateProfile)

        var payload: Any {
            switch self {
            case let .changePublishQuality(event):
                return event
            case let .didUpdateCallSettings(callSettings):
                return callSettings
            case let .didUpdateCameraPosition(position):
                return position
            case let .mid(type):
                return type
            case let .localTrack(type):
                return type
            case .restartICE:
                return ()
            case .close:
                return ()
            case let .setVideoFilter(videoFilter):
                return videoFilter as Any
            case .ensureSetUpHasBeenCompleted:
                return ()
            case let .setUp(settings, ownCapabilities):
                return (settings, ownCapabilities)
            case let .beginScreenSharing(type, ownCapabilities, includeAudio):
                return (type, ownCapabilities, includeAudio)
            case .stopScreenSharing:
                return ()
            case let .focus(point):
                return point
            case let .addCapturePhotoOutput(capturePhotoOutput):
                return capturePhotoOutput
            case let .removeCapturePhotoOutput(capturePhotoOutput):
                return capturePhotoOutput
            case let .addVideoOutput(videoOutput):
                return videoOutput
            case let .removeVideoOutput(videoOutput):
                return videoOutput
            case let .zoom(factor):
                return factor
            case let .trackInfo(trackType):
                return trackType
            case .statsReport:
                return ()
            case let .setAudioMaxBitrate(bitrate):
                return bitrate
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

    private func record(_ input: MockFunctionInputKey, for function: FunctionKey) {
        _stubbedFunctionInput.mutate {
            $0[function]?.append(input)
        }
    }

    // MARK: - Overrides

    var stubbedMid: [TrackType: String] = [:]
    var stubbedTrack: [TrackType: RTCMediaStreamTrack] = [:]
    var stubbedTrackInfo: [TrackType: [Stream_Video_Sfu_Models_TrackInfo]] = [:]
    let stubEventSubject: PassthroughSubject<RTCPeerConnectionEvent, Never> = .init()

    override var disconnectedPublisher: AnyPublisher<Void, Never> {
        if let stub = stubbedProperty[propertyKey(for: \.disconnectedPublisher)] as? AnyPublisher<Void, Never> {
            return stub
        } else {
            return super.disconnectedPublisher
        }
    }

    override var eventPublisher: AnyPublisher<RTCPeerConnectionEvent, Never> {
        stubEventSubject.eraseToAnyPublisher()
    }

    override var connectionStatePublisher: AnyPublisher<RTCPeerConnectionState, Never> {
        if let stub = stubbedProperty[
            propertyKey(for: \.connectionStatePublisher)
        ] as? AnyPublisher<RTCPeerConnectionState, Never> {
            return stub
        } else {
            return super.connectionStatePublisher
        }
    }

    override var iceConnectionStatePublisher: AnyPublisher<RTCIceConnectionState, Never> {
        if let stub = stubbedProperty[
            propertyKey(for: \.iceConnectionStatePublisher)
        ] as? AnyPublisher<RTCIceConnectionState, Never> {
            return stub
        } else {
            return super.iceConnectionStatePublisher
        }
    }

    override var isHealthy: Bool {
        self[dynamicMember: \.isHealthy]
    }

    convenience init?(
        sessionId: String = .unique,
        peerType: PeerConnectionType,
        videoOptions: VideoOptions = .init(),
        videoConfig: VideoConfig = .dummy(),
        callSettings: CallSettings = .init(),
        audioSettings: AudioSettings = .init(),
        publishOptions: PublishOptions = .init(),
        sfuAdapter: SFUAdapter,
        videoCaptureSessionProvider: VideoCaptureSessionProvider = .init(),
        screenShareSessionProvider: ScreenShareSessionProvider = .init(),
        iceAdapter: ICEAdapter? = nil,
        iceConnectionStateAdapter: ICEConnectionStateAdapter? = nil,
        audioDeviceModule: AudioDeviceModule = .init(MockRTCAudioDeviceModule())
    ) throws {
        let peerConnectionFactory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule.shared
        )

        let sessionId = String.unique
        let peerConnection = MockRTCPeerConnection()
        self.init(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            videoOptions: videoOptions,
            callSettings: callSettings,
            audioSettings: audioSettings,
            publishOptions: publishOptions,
            sfuAdapter: sfuAdapter,
            mediaAdapter: .init(
                sessionID: sessionId,
                peerConnectionType: peerType,
                peerConnection: peerConnection,
                peerConnectionFactory: peerConnectionFactory,
                sfuAdapter: sfuAdapter,
                videoOptions: videoOptions,
                videoConfig: videoConfig,
                publishOptions: publishOptions,
                videoCaptureSessionProvider: videoCaptureSessionProvider,
                screenShareSessionProvider: screenShareSessionProvider,
                audioDeviceModule: audioDeviceModule
            ),
            iceAdapter: iceAdapter ?? .init(
                sessionID: sessionId,
                peerType: peerType,
                peerConnection: peerConnection,
                sfuAdapter: sfuAdapter
            ),
            iceConnectionStateAdapter: iceConnectionStateAdapter ?? .init(),
            clientCapabilities: []
        )

        stub(for: \.isHealthy, with: true)
    }

    override func changePublishQuality(
        with event: Stream_Video_Sfu_Event_ChangePublishQuality
    ) {
        record(.changePublishQuality(event: event), for: .changePublishQuality)
    }

    override func didUpdateCallSettings(_ settings: CallSettings) async throws {
        record(.didUpdateCallSettings(callSettings: settings), for: .didUpdateCallSettings)

        if let result = stubbedFunction[.didUpdateCallSettings] as? Result<Void, Error> {
            switch result {
            case .success:
                break
            case let .failure(error):
                throw error
            }
        }
    }

    override func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        record(.didUpdateCameraPosition(position: position), for: .didUpdateCameraPosition)
    }

    override func restartICE() {
        record(.restartICE, for: .restartICE)
    }

    override func close() async {
        record(.close, for: .close)
    }

    override func setVideoFilter(_ videoFilter: VideoFilter?) {
        record(.setVideoFilter(videoFilter: videoFilter), for: .setVideoFilter)
    }

    override func setAudioMaxBitrate(for profile: AudioBitrateProfile) async {
        record(.setAudioMaxBitrate(profile), for: .setAudioMaxBitrate)
    }

    override func ensureSetUpHasBeenCompleted() async throws {
        record(.ensureSetUpHasBeenCompleted, for: .ensureSetUpHasBeenCompleted)

        if let result = stubbedFunction[.ensureSetUpHasBeenCompleted] as? Error {
            throw result
        }
    }

    override func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        record(
            .setUp(settings: settings, ownCapabilities: ownCapabilities),
            for: .setUp
        )
    }

    override func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability],
        includeAudio: Bool
    ) async throws {
        record(
            .beginScreenSharing(
                type: type,
                ownCapabilities: ownCapabilities,
                includeAudio: includeAudio
            ),
            for: .beginScreenSharing
        )
    }

    override func stopScreenSharing() async throws {
        record(.stopScreenSharing, for: .stopScreenSharing)
    }

    override func focus(at point: CGPoint) async throws {
        record(.focus(point: point), for: .focus)
    }

    override func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        record(
            .addCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput),
            for: .addCapturePhotoOutput
        )
    }

    override func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        record(
            .removeCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput),
            for: .removeCapturePhotoOutput
        )
    }

    override func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        record(
            .addVideoOutput(videoOutput: videoOutput),
            for: .addVideoOutput
        )
    }

    override func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        record(
            .removeVideoOutput(videoOutput: videoOutput),
            for: .removeVideoOutput
        )
    }

    override func zoom(by factor: CGFloat) async throws {
        record(.zoom(factor: factor), for: .zoom)
    }

    override func trackInfo(
        for type: TrackType,
        collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        record(.trackInfo(trackType: type), for: .trackInfo)
        return stubbedTrackInfo[type] ?? []
    }

    override func statsReport() async throws -> StreamRTCStatisticsReport {
        record(.statsReport, for: .statsReport)
        return (stubbedFunction[.statsReport] as? StreamRTCStatisticsReport) ?? .init(nil)
    }
}
