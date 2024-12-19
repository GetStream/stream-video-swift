//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

final class MockRTCRtpCodecCapability: RTCRtpCodecCapabilityProtocol, Mockable {
    enum MockFunctionKey: Hashable, CaseIterable { case none }
    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = EmptyPayloadable
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [MockFunctionKey: Any] = [:]
    var stubbedFunctionInput: [MockFunctionKey: [FunctionInputKey]] = [:]
    func stub<T>(for keyPath: KeyPath<MockRTCRtpCodecCapability, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    var name: String { self[dynamicMember: \.name] }
    var fmtp: String { self[dynamicMember: \.fmtp] }
    var clockRate: NSNumber? { self[dynamicMember: \.clockRate] }
    var preferredPayloadType: NSNumber? { self[dynamicMember: \.preferredPayloadType] }
}
