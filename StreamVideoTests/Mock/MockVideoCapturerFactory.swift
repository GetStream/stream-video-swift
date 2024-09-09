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
            source: RTCVideoSource,
            options: VideoOptions,
            filters: [VideoFilter]
        )
        case buildScreenCapturer(
            type: ScreensharingType,
            source: RTCVideoSource,
            options: VideoOptions,
            filters: [VideoFilter]
        )

        var payload: Any {
            switch self {
            case let .buildCameraCapturer(source, options, filters):
                return (source, options, filters)
            case let .buildScreenCapturer(type, source, options, filters):
                return (type, source, options, filters)
            }
        }
    }

    init() {
        stub(for: .buildCameraCapturer, with: MockCameraVideoCapturer())
        stub(for: .buildScreenCapturer, with: MockVideoCapturer())
    }

    // MARK: - VideoCapturerProviding

    func buildCameraCapturer(
        source: RTCVideoSource,
        options: VideoOptions,
        filters: [VideoFilter]
    ) -> CameraVideoCapturing {
        stubbedFunctionInput[.buildCameraCapturer]?
            .append(
                .buildCameraCapturer(
                    source: source,
                    options: options,
                    filters: filters
                )
            )
        return stubbedFunction[.buildCameraCapturer] as! CameraVideoCapturing
    }
    
    func buildScreenCapturer(
        _ type: ScreensharingType,
        source: RTCVideoSource,
        options: VideoOptions,
        filters: [VideoFilter]
    ) -> VideoCapturing {
        stubbedFunctionInput[.buildScreenCapturer]?
            .append(
                .buildScreenCapturer(
                    type: type,
                    source: source,
                    options: options,
                    filters: filters
                )
            )
        return stubbedFunction[.buildScreenCapturer] as! VideoCapturing
    }
}
