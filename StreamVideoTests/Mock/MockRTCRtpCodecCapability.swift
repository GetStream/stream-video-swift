//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    func stub(for function: FunctionKey, with value: some Any) {
        stubbedFunction[function] = value
    }

    func propertyKey(for keyPath: KeyPath<MockRTCRtpCodecCapability, some Any>) -> String {
        switch keyPath {
        case \.name:
            MockPropertyKey.name.rawValue
        case \.fmtp:
            MockPropertyKey.fmtp.rawValue
        case \.clockRate:
            MockPropertyKey.clockRate.rawValue
        case \.preferredPayloadType:
            MockPropertyKey.preferredPayloadType.rawValue
        default:
            fatalError()
        }
    }

    var name: String { self[dynamicMember: \.name] }
    var fmtp: String { self[dynamicMember: \.fmtp] }
    var clockRate: NSNumber? { self[dynamicMember: \.clockRate] }
    var preferredPayloadType: NSNumber? { self[dynamicMember: \.preferredPayloadType] }
}
