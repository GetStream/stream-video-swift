//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo

final class MockVideoCapturer: VideoCapturing, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockVideoCapturer, T>, with value: T) { stubbedProperty[propertyKey(for: keyPath)] = value }
    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case startCapture
        case stopCapture
    }

    enum MockFunctionInputKey: Payloadable {
        case startCapture(device: AVCaptureDevice?)
        case stopCapture

        var payload: Any {
            switch self {
            case let .startCapture(device):
                return device
            case .stopCapture:
                return ()
            }
        }
    }

    // MARK: - VideoCapturing

    func startCapture(device: AVCaptureDevice?) async throws {
        stubbedFunctionInput[.startCapture]?
            .append(.startCapture(device: device))
    }

    func stopCapture() async throws {
        stubbedFunctionInput[.stopCapture]?
            .append(.stopCapture)
    }
}
