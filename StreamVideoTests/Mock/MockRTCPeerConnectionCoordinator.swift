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
        stubbedFunctionInput[.changePublishQuality]?
            .append(.changePublishQuality(event: event))
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

    override func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        stubbedFunctionInput[.didUpdateCameraPosition]?
            .append(.didUpdateCameraPosition(position: position))
    }

    override func restartICE() {
        stubbedFunctionInput[.restartICE]?.append(.restartICE)
    }

    override func close() async {
        stubbedFunctionInput[.close]?.append(.close)
    }

    override func setVideoFilter(_ videoFilter: VideoFilter?) {
        stubbedFunctionInput[.setVideoFilter]?.append(
            .setVideoFilter(
                videoFilter: videoFilter
            )
        )
    }

    override func ensureSetUpHasBeenCompleted() async throws {
        stubbedFunctionInput[.ensureSetUpHasBeenCompleted]?
            .append(.ensureSetUpHasBeenCompleted)

        if let result = stubbedFunction[.ensureSetUpHasBeenCompleted] as? Error {
            throw result
        }
    }

    override func setUp(
        with settings: CallSettings,
        ownCapabilities: [OwnCapability]
    ) async throws {
        stubbedFunctionInput[.setUp]?.append(
            .setUp(settings: settings, ownCapabilities: ownCapabilities)
        )
    }

    override func beginScreenSharing(
        of type: ScreensharingType,
        ownCapabilities: [OwnCapability],
        includeAudio: Bool
    ) async throws {
        stubbedFunctionInput[.beginScreenSharing]?.append(
            .beginScreenSharing(
                type: type,
                ownCapabilities: ownCapabilities,
                includeAudio: includeAudio
            )
        )
    }

    override func stopScreenSharing() async throws {
        stubbedFunctionInput[.stopScreenSharing]?.append(.stopScreenSharing)
    }

    override func focus(at point: CGPoint) async throws {
        stubbedFunctionInput[.focus]?.append(
            .focus(point: point)
        )
    }

    override func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        stubbedFunctionInput[.addCapturePhotoOutput]?.append(
            .addCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput)
        )
    }

    override func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        stubbedFunctionInput[.removeCapturePhotoOutput]?.append(
            .removeCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput)
        )
    }

    override func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        stubbedFunctionInput[.addVideoOutput]?.append(
            .addVideoOutput(videoOutput: videoOutput)
        )
    }

    override func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        stubbedFunctionInput[.removeVideoOutput]?.append(
            .removeVideoOutput(videoOutput: videoOutput)
        )
    }

    override func zoom(by factor: CGFloat) async throws {
        stubbedFunctionInput[.zoom]?.append(
            .zoom(factor: factor)
        )
    }

    override func trackInfo(
        for type: TrackType,
        collectionType: RTCPeerConnectionTrackInfoCollectionType
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        stubbedFunctionInput[.trackInfo]?.append(
            .trackInfo(trackType: type)
        )
        return stubbedTrackInfo[type] ?? []
    }

    override func statsReport() async throws -> StreamRTCStatisticsReport {
        stubbedFunctionInput[.statsReport]?.append(.statsReport)
        return (stubbedFunction[.statsReport] as? StreamRTCStatisticsReport) ?? .init(nil)
    }
}
