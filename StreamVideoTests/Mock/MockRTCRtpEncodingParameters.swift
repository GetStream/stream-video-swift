//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC

final class MockRTCRtpEncodingParameters: RTCRtpEncodingParametersProtocol, Mockable, @unchecked Sendable {
    enum MockFunctionKey: Hashable, CaseIterable { case none }
    enum MockPropertyKey: String, Hashable { case rid, maxBitrateBps, maxFramerate }
    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = EmptyPayloadable
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [MockFunctionKey: Any] = [:]
    var stubbedFunctionInput: [MockFunctionKey: [FunctionInputKey]] = [:]
    func stub<T>(for keyPath: KeyPath<MockRTCRtpEncodingParameters, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub(for function: FunctionKey, with value: some Any) {
        stubbedFunction[function] = value
    }

    func propertyKey(for keyPath: KeyPath<MockRTCRtpEncodingParameters, some Any>) -> String {
        switch keyPath {
        case \.rid:
            MockPropertyKey.rid.rawValue
        case \.maxBitrateBps:
            MockPropertyKey.maxBitrateBps.rawValue
        case \.maxFramerate:
            MockPropertyKey.maxFramerate.rawValue
        default:
            fatalError()
        }
    }

    var rid: String? { self[dynamicMember: \.rid] }
    var maxBitrateBps: NSNumber? { self[dynamicMember: \.maxBitrateBps] }
    var maxFramerate: NSNumber? { self[dynamicMember: \.maxFramerate] }
}
