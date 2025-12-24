//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

final class MockVideoCapturerFactory: VideoCapturerProviding, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockVideoCapturerFactory, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case buildCameraCapturer
        case buildScreenCapturer
    }

    enum MockFunctionInputKey: Payloadable {
        case buildCameraCapturer(
            source: RTCVideoSource,
            audioDeviceModule: AudioDeviceModule
        )
        case buildScreenCapturer(
            type: ScreensharingType,
            source: RTCVideoSource,
            audioDeviceModule: AudioDeviceModule,
            includeAudio: Bool
        )

        var payload: Any {
            switch self {
            case let .buildCameraCapturer(source, audioDeviceModule):
                return (source, audioDeviceModule)
            case let .buildScreenCapturer(type, source, audioDeviceModule, includeAudio):
                return (type, source, audioDeviceModule, includeAudio)
            }
        }
    }

    init() {
        stub(for: .buildCameraCapturer, with: MockStreamVideoCapturer())
        stub(for: .buildScreenCapturer, with: MockStreamVideoCapturer())
    }

    // MARK: - VideoCapturerProviding

    func buildCameraCapturer(
        source: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule
    ) -> StreamVideoCapturing {
        stubbedFunctionInput[.buildCameraCapturer]?
            .append(
                .buildCameraCapturer(
                    source: source,
                    audioDeviceModule: audioDeviceModule
                )
            )
        return stubbedFunction[.buildCameraCapturer] as! StreamVideoCapturing
    }
    
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource,
        audioDeviceModule: AudioDeviceModule,
        includeAudio: Bool
    ) -> StreamVideoCapturing {
        stubbedFunctionInput[.buildScreenCapturer]?
            .append(
                .buildScreenCapturer(
                    type: type,
                    source: source,
                    audioDeviceModule: audioDeviceModule,
                    includeAudio: includeAudio
                )
            )
        return stubbedFunction[.buildScreenCapturer] as! StreamVideoCapturing
    }
}
