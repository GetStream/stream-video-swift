//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

final class MockRTCRtpCodecCapability: NSObject, RTCRtpCodecCapabilityProtocol, Mockable, @unchecked Sendable {
    enum MockFunctionKey: Hashable, CaseIterable { case none }
    enum MockPropertyKey: String, Hashable { case name, fmtp, clockRate, preferredPayloadType }
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

    func propertyKey<T>(for keyPath: KeyPath<MockRTCRtpCodecCapability, T>) -> String {
        switch keyPath {
        case \.name:
            return MockPropertyKey.name.rawValue
        case \.fmtp:
            return MockPropertyKey.fmtp.rawValue
        case \.clockRate:
            return MockPropertyKey.clockRate.rawValue
        case \.preferredPayloadType:
            return MockPropertyKey.preferredPayloadType.rawValue
        default:
            fatalError()
        }
    }

    var name: String { self[dynamicMember: \.name] }
    var fmtp: String { self[dynamicMember: \.fmtp] }
    var clockRate: NSNumber? { self[dynamicMember: \.clockRate] }
    var preferredPayloadType: NSNumber? { self[dynamicMember: \.preferredPayloadType] }
}
