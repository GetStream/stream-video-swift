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
        case setVideoFilter
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
    }

    enum MockFunctionInputKey: Payloadable {
        case changePublishQuality(activeEncodings: Set<String>)
        case didUpdateCallSettings(callSettings: CallSettings)
        case didUpdateCameraPosition(position: AVCaptureDevice.Position)
        case mid(type: TrackType)
        case localTrack(type: TrackType)
        case restartICE
        case close
        case setVideoFilter(videoFilter: VideoFilter?)
        case setUp(settings: CallSettings, ownCapabilities: [OwnCapability])
        case beginScreenSharing(type: ScreensharingType, ownCapabilities: [OwnCapability])
        case stopScreenSharing
        case focus(point: CGPoint)
        case addCapturePhotoOutput(capturePhotoOutput: AVCapturePhotoOutput)
        case removeCapturePhotoOutput(capturePhotoOutput: AVCapturePhotoOutput)
        case addVideoOutput(videoOutput: AVCaptureVideoDataOutput)
        case removeVideoOutput(videoOutput: AVCaptureVideoDataOutput)
        case zoom(factor: CGFloat)

        var payload: Any {
            switch self {
            case let .changePublishQuality(activeEncodings):
                return activeEncodings
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
                return videoFilter
            case let .setUp(settings, ownCapabilities):
                return (settings, ownCapabilities)
            case let .beginScreenSharing(type, ownCapabilities):
                return (type, ownCapabilities)
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

    override func didUpdateCameraPosition(
        _ position: AVCaptureDevice.Position
    ) async throws {
        stubbedFunctionInput[.didUpdateCameraPosition]?
            .append(.didUpdateCameraPosition(position: position))
    }

    override func mid(for type: TrackType) -> String? {
        stubbedFunctionInput[.mid]?.append(.mid(type: type))
        if let result = stubbedMid[type] {
            return result
        } else if let result = stubbedFunction[.mid] as? String {
            return result
        } else {
            return nil
        }
    }

    override func localTrack(of type: TrackType) -> RTCMediaStreamTrack? {
        stubbedFunctionInput[.localTrack]?.append(.mid(type: type))
        if let result = stubbedTrack[type] {
            return result
        } else if let result = stubbedFunction[.localTrack] as? RTCMediaStreamTrack {
            return result
        } else {
            return nil
        }
    }

    override func restartICE() {
        stubbedFunctionInput[.restartICE]?.append(.restartICE)
    }

    override func close() {
        stubbedFunctionInput[.close]?.append(.close)
    }

    override func setVideoFilter(_ videoFilter: VideoFilter?) {
        stubbedFunctionInput[.setVideoFilter]?.append(
            .setVideoFilter(
                videoFilter: videoFilter
            )
        )
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
        ownCapabilities: [OwnCapability]
    ) async throws {
        stubbedFunctionInput[.beginScreenSharing]?.append(
            .beginScreenSharing(type: type, ownCapabilities: ownCapabilities)
        )
    }

    override func stopScreenSharing() async throws {
        stubbedFunctionInput[.stopScreenSharing]?.append(.stopScreenSharing)
    }

    override func focus(at point: CGPoint) throws {
        stubbedFunctionInput[.focus]?.append(
            .focus(point: point)
        )
    }

    override func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        stubbedFunctionInput[.addCapturePhotoOutput]?.append(
            .addCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput)
        )
    }

    override func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) throws {
        stubbedFunctionInput[.removeCapturePhotoOutput]?.append(
            .removeCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput)
        )
    }

    override func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        stubbedFunctionInput[.addVideoOutput]?.append(
            .addVideoOutput(videoOutput: videoOutput)
        )
    }

    override func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) throws {
        stubbedFunctionInput[.removeVideoOutput]?.append(
            .removeVideoOutput(videoOutput: videoOutput)
        )
    }

    override func zoom(by factor: CGFloat) throws {
        stubbedFunctionInput[.zoom]?.append(
            .zoom(factor: factor)
        )
    }
}
