//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockRTCAudioDeviceModule: RTCAudioDeviceModuleControlling, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case initAndStartRecording
        case stopRecording
        case setMicrophoneMuted
        case microphoneMutedPublisher
    }

    enum MockFunctionInputKey: Payloadable {
        case initAndStartRecording
        case stopRecording
        case setMicrophoneMuted(Bool)
        case microphoneMutedPublisher

        var payload: Any {
            switch self {
            case .initAndStartRecording:
                return ()

            case .stopRecording:
                return ()

            case .setMicrophoneMuted(let value):
                return value

            case .microphoneMutedPublisher:
                return ()
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] =
        MockFunctionKey.allCases.reduce(into: [:]) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockRTCAudioDeviceModule, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    init() {
        stub(for: \.isMicrophoneMuted, with: false)
    }

    // MARK: - RTCAudioDeviceModuleControlling

    let microphoneMutedSubject: CurrentValueSubject<Bool, Never> = .init(false)

    var observer: (any RTCAudioDeviceModuleDelegate)?

    var isMicrophoneMuted: Bool {
        get { self[dynamicMember: \.isMicrophoneMuted] }
        set { _ = newValue }
    }

    func initAndStartRecording() -> Int {
        stubbedFunctionInput[.initAndStartRecording]?
            .append(.initAndStartRecording)
        return stubbedFunction[.initAndStartRecording] as? Int ?? 0
    }

    func setMicrophoneMuted(_ isMuted: Bool) -> Int {
        stubbedFunctionInput[.setMicrophoneMuted]?
            .append(.setMicrophoneMuted(isMuted))
        return stubbedFunction[.setMicrophoneMuted] as? Int ?? 0
    }

    func stopRecording() -> Int {
        stubbedFunctionInput[.stopRecording]?
            .append(.stopRecording)
        return stubbedFunction[.stopRecording] as? Int ?? 0
    }

    func microphoneMutedPublisher() -> AnyPublisher<Bool, Never> {
        stubbedFunctionInput[.microphoneMutedPublisher]?
            .append(.microphoneMutedPublisher)
        return microphoneMutedSubject.eraseToAnyPublisher()
    }
}
