//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC

final class MockCaptureDeviceProvider: CaptureDeviceProviding, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    enum MockFunctionKey: Hashable, CaseIterable {
        case deviceForAVPosition
        case deviceForPosition
    }

    enum MockFunctionInputKey: Payloadable {
        case deviceForAVPosition(position: AVCaptureDevice.Position)
        case deviceForPosition(position: CameraPosition)

        var payload: Any {
            switch self {
            case let .deviceForAVPosition(position):
                return position
            case let .deviceForPosition(position):
                return position
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockCaptureDeviceProvider, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    // MARK: - CaptureDeviceProviding

    func device(
        for position: AVCaptureDevice.Position
    ) -> CaptureDeviceProtocol? {
        stubbedFunctionInput[.deviceForAVPosition]?.append(
            .deviceForAVPosition(position: position)
        )
        return stubbedFunction[.deviceForAVPosition] as? CaptureDeviceProtocol
    }

    func device(
        for position: CameraPosition
    ) -> CaptureDeviceProtocol? {
        stubbedFunctionInput[.deviceForPosition]?.append(
            .deviceForPosition(position: position)
        )
        return stubbedFunction[.deviceForPosition] as? CaptureDeviceProtocol
    }
}
