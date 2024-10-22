//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo

final class MockCameraVideoCapturer: CameraVideoCapturing, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockCameraVideoCapturer, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case setCameraPosition
        case setVideoFilter
        case capturingDevice
        case zoom
        case focus
        case addVideoOutput
        case removeVideoOutput
        case addCapturePhotoOutput
        case removeCapturePhotoOutput
        case startCapture
        case stopCapture
        case updateCaptureQuality
    }

    enum MockFunctionInputKey: Payloadable {
        case setCameraPosition(cameraPosition: AVCaptureDevice.Position)
        case setVideoFilter(videoFilter: VideoFilter?)
        case capturingDevice(cameraPosition: AVCaptureDevice.Position)
        case zoom(factor: CGFloat)
        case focus(point: CGPoint)
        case addVideoOutput(videoOutput: AVCaptureVideoDataOutput)
        case removeVideoOutput(videoOutput: AVCaptureVideoDataOutput)
        case addCapturePhotoOutput(capturePhotoOutput: AVCapturePhotoOutput)
        case removeCapturePhotoOutput(capturePhotoOutput: AVCapturePhotoOutput)
        case startCapture(device: AVCaptureDevice?)
        case stopCapture
        case updateCaptureQuality(codecs: [VideoLayer], device: AVCaptureDevice?)

        var payload: Any {
            switch self {
            case let .setCameraPosition(cameraPosition):
                return cameraPosition
            case let .setVideoFilter(videoFilter):
                return videoFilter
            case let .zoom(factor):
                return factor
            case let .capturingDevice(cameraPosition):
                return cameraPosition
            case let .startCapture(device):
                return device
            case .stopCapture:
                return ()
            case let .focus(point: point):
                return point
            case let .addVideoOutput(videoOutput):
                return videoOutput
            case let .removeVideoOutput(videoOutput):
                return videoOutput
            case let .addCapturePhotoOutput(capturePhotoOutput):
                return capturePhotoOutput
            case let .removeCapturePhotoOutput(capturePhotoOutput):
                return capturePhotoOutput
            case let .updateCaptureQuality(codecs, device):
                return (codecs, device)
            }
        }
    }

    // MARK: - CameraVideoCapturing

    func setCameraPosition(
        _ cameraPosition: AVCaptureDevice.Position
    ) async throws {
        stubbedFunctionInput[.setCameraPosition]?
            .append(.setCameraPosition(cameraPosition: cameraPosition))
    }

    func capturingDevice(
        for cameraPosition: AVCaptureDevice.Position
    ) -> AVCaptureDevice? {
        stubbedFunctionInput[.capturingDevice]?
            .append(.capturingDevice(cameraPosition: cameraPosition))
        return stubbedFunction[.capturingDevice] as? AVCaptureDevice
    }

    func startCapture(device: AVCaptureDevice?) async throws {
        stubbedFunctionInput[.startCapture]?
            .append(.startCapture(device: device))
    }

    func stopCapture() async throws {
        stubbedFunctionInput[.stopCapture]?
            .append(.stopCapture)
    }

    func updateCaptureQuality(
        _ codecs: [VideoLayer],
        on device: AVCaptureDevice?
    ) async {
        stubbedFunctionInput[.updateCaptureQuality]?
            .append(.updateCaptureQuality(codecs: codecs, device: device))
    }

    func setVideoFilter(_ videoFilter: VideoFilter?) {
        stubbedFunctionInput[.setVideoFilter]?
            .append(.setVideoFilter(videoFilter: videoFilter))
    }

    func zoom(by factor: CGFloat) throws {
        stubbedFunctionInput[.zoom]?.append(.zoom(factor: factor))
    }

    func focus(at point: CGPoint) throws {
        stubbedFunctionInput[.focus]?.append(.focus(point: point))
    }

    func addVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        stubbedFunctionInput[.addVideoOutput]?
            .append(.addVideoOutput(videoOutput: videoOutput))
    }

    func removeVideoOutput(_ videoOutput: AVCaptureVideoDataOutput) throws {
        stubbedFunctionInput[.removeVideoOutput]?
            .append(.removeVideoOutput(videoOutput: videoOutput))
    }

    func addCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        stubbedFunctionInput[.addCapturePhotoOutput]?
            .append(.addCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput))
    }

    func removeCapturePhotoOutput(_ capturePhotoOutput: AVCapturePhotoOutput) throws {
        stubbedFunctionInput[.removeCapturePhotoOutput]?
            .append(.removeCapturePhotoOutput(capturePhotoOutput: capturePhotoOutput))
    }
}
