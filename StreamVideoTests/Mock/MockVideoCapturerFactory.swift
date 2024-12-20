//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

final class MockVideoCapturerFactory: VideoCapturerProviding, Mockable {

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
            source: RTCVideoSource
        )
        case buildScreenCapturer(
            type: ScreensharingType,
            source: RTCVideoSource
        )

        var payload: Any {
            switch self {
            case let .buildCameraCapturer(source):
                return (source)
            case let .buildScreenCapturer(type, source):
                return (type, source)
            }
        }
    }

    init() {
        stub(for: .buildCameraCapturer, with: MockStreamVideoCapturer())
        stub(for: .buildScreenCapturer, with: MockStreamVideoCapturer())
    }

    // MARK: - VideoCapturerProviding

    func buildCameraCapturer(
        source: RTCVideoSource
    ) -> StreamVideoCapturing {
        stubbedFunctionInput[.buildCameraCapturer]?
            .append(
                .buildCameraCapturer(
                    source: source
                )
            )
        return stubbedFunction[.buildCameraCapturer] as! StreamVideoCapturing
    }
    
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource
    ) -> StreamVideoCapturing {
        stubbedFunctionInput[.buildScreenCapturer]?
            .append(
                .buildScreenCapturer(
                    type: type,
                    source: source
                )
            )
        return stubbedFunction[.buildScreenCapturer] as! StreamVideoCapturing
    }
}
