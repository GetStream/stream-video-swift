//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC

final class MockStreamVideoCapturer: StreamVideoCapturing, Mockable, @unchecked Sendable {
    enum MockFunctionKey: Hashable, CaseIterable {
        case startCapture
        case stopCapture
        case setCameraPosition
        case setVideoFilter
        case updateCaptureQuality
        case focus
        case zoom
        case addCapturePhotoOutput
        case removeCapturePhotoOutput
        case addVideoOutput
        case removeVideoOutput
        case supportsBackgrounding
    }

    enum MockCallFunctionInputKey: Payloadable {
        case startCapture(
            position: AVCaptureDevice.Position,
            dimensions: CGSize,
            frameRate: Int
        )
        case stopCapture
        case setCameraPosition(position: AVCaptureDevice.Position)
        case setVideoFilter(videoFilter: VideoFilter?)
        case updateCaptureQuality(dimensions: CGSize)
        case focus(point: CGPoint)
        case zoom(factor: CGFloat)
        case addCapturePhotoOutput(capturePhotoOutput: AVCapturePhotoOutput)
        case removeCapturePhotoOutput(capturePhotoOutput: AVCapturePhotoOutput)
        case addVideoOutput(videoOutput: AVCaptureVideoDataOutput)
        case removeVideoOutput(videoOutput: AVCaptureVideoDataOutput)

        var payload: Any {
            switch self {
            case let .startCapture(position, dimensions, frameRate):
                return (position, dimensions, frameRate)
            case .stopCapture:
                return ()
            case let .setCameraPosition(position):
                return position
            case let .setVideoFilter(videoFilter):
                return videoFilter!
            case let .updateCaptureQuality(dimensions):
                return dimensions
            case let .focus(point):
                return point
            case let .zoom(factor):
                return factor
            case let .addCapturePhotoOutput(capturePhotoOutput):
                return capturePhotoOutput
            case let .removeCapturePhotoOutput(capturePhotoOutput):
                return capturePhotoOutput
            case let .addVideoOutput(videoOutput):
                return videoOutput
            case let .removeVideoOutput(videoOutput):
                return videoOutput
            }
        }
    }

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockCallFunctionInputKey

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [MockFunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockStreamVideoCapturer, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    func supportsBackgrounding() async -> Bool {
        (stubbedFunction[.supportsBackgrounding] as? Bool) ?? false
    }

    func startCapture(
        position: AVCaptureDevice.Position,
        dimensions: CGSize,
        frameRate: Int
    ) async throws {
        stubbedFunctionInput[.startCapture]?.append(
            .startCapture(
                position: position,
                dimensions: dimensions,
                frameRate: frameRate
            )
        )
    }

    func stopCapture() async throws {
        stubbedFunctionInput[.stopCapture]?.append(.stopCapture)
    }

    func setCameraPosition(_ position: AVCaptureDevice.Position) async throws {
        stubbedFunctionInput[.setCameraPosition]?.append(.setCameraPosition(position: position))
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        stubbedFunctionInput[.setVideoFilter]?.append(.setVideoFilter(videoFilter: videoFilter))
    }

    func updateCaptureQuality(
        _ dimensions: CGSize
    ) async throws {
        stubbedFunctionInput[.updateCaptureQuality]?
            .append(.updateCaptureQuality(dimensions: dimensions))
    }

    func focus(at point: CGPoint) async throws {
        stubbedFunctionInput[.focus]?.append(.focus(point: point))
    }

    func zoom(by factor: CGFloat) async throws {
        stubbedFunctionInput[.zoom]?.append(.zoom(factor: factor))
    }

    func addCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        stubbedFunctionInput[.addCapturePhotoOutput]?.append(.addCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput))
    }

    func removeCapturePhotoOutput(
        _ capturePhotoOutput: AVCapturePhotoOutput
    ) async throws {
        stubbedFunctionInput[.removeCapturePhotoOutput]?.append(.removeCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput))
    }

    func addVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        stubbedFunctionInput[.addVideoOutput]?.append(.addVideoOutput(videoOutput: videoOutput))
    }

    func removeVideoOutput(
        _ videoOutput: AVCaptureVideoDataOutput
    ) async throws {
        stubbedFunctionInput[.removeVideoOutput]?.append(.removeVideoOutput(videoOutput: videoOutput))
    }
}
