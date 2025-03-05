//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CoreMedia
@testable import StreamVideo

final class MockCaptureDevice: CaptureDeviceProtocol, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockCaptureDevice, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {}

    enum MockFunctionKey: Hashable, CaseIterable {
        case outputFormat
    }

    enum MockFunctionInputKey: Payloadable {
        case outputFormat(preferredDimensions: CMVideoDimensions, preferredFrameRate: Int)

        var payload: Any {
            switch self {
            case let .outputFormat(preferredDimensions, preferredFrameRate):
                return (preferredDimensions, preferredFrameRate)
            }
        }
    }

    var position: AVCaptureDevice.Position {
        get { self[dynamicMember: \.position] }
        set { _ = newValue }
    }

    func outputFormat(
        preferredDimensions: CMVideoDimensions,
        preferredFrameRate: Int
    ) -> AVCaptureDevice.Format? {
        stubbedFunctionInput[.outputFormat]?.append(
            .outputFormat(
                preferredDimensions: preferredDimensions,
                preferredFrameRate: preferredFrameRate
            )
        )

        return stubbedFunction[.outputFormat] as? AVCaptureDevice.Format
    }
}
