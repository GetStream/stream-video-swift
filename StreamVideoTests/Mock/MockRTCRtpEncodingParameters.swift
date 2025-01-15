//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

final class MockRTCRtpEncodingParameters: RTCRtpEncodingParametersProtocol, Mockable {
    enum MockFunctionKey: Hashable, CaseIterable { case none }
    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = EmptyPayloadable
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [MockFunctionKey: Any] = [:]
    var stubbedFunctionInput: [MockFunctionKey: [FunctionInputKey]] = [:]
    func stub<T>(for keyPath: KeyPath<MockRTCRtpEncodingParameters, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    var rid: String? { self[dynamicMember: \.rid] }
    var maxBitrateBps: NSNumber? { self[dynamicMember: \.maxBitrateBps] }
    var maxFramerate: NSNumber? { self[dynamicMember: \.maxFramerate] }
}
