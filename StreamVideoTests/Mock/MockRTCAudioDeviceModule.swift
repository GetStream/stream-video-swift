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
        case setMicrophoneMuted
        case microphoneMutedPublisher
        case reset
        case initAndStartPlayout
        case startPlayout
        case stopPlayout
        case initAndStartRecording
        case startRecording
        case stopRecording
        case refreshStereoPlayoutState
        case setMuteMode
        case setRecordingAlwaysPreparedMode
    }

    enum MockFunctionInputKey: Payloadable {
        case setMicrophoneMuted(Bool)
        case microphoneMutedPublisher
        case reset
        case initAndStartPlayout
        case startPlayout
        case stopPlayout
        case initAndStartRecording
        case startRecording
        case stopRecording
        case refreshStereoPlayoutState
        case setMuteMode(RTCAudioEngineMuteMode)
        case setRecordingAlwaysPreparedMode(Bool)

        var payload: Any {
            switch self {

            case .setMicrophoneMuted(let value):
                return value

            case .microphoneMutedPublisher:
                return ()

            case .reset:
                return ()

            case .initAndStartPlayout:
                return ()

            case .startPlayout:
                return ()

            case .stopPlayout:
                return ()

            case .initAndStartRecording:
                return ()

            case .startRecording:
                return ()

            case .stopRecording:
                return ()

            case .refreshStereoPlayoutState:
                return ()

            case let .setMuteMode(value):
                return value

            case let .setRecordingAlwaysPreparedMode(value):
                return value
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
        stub(for: \.isPlaying, with: false)
        stub(for: \.isRecording, with: false)
        stub(for: \.isPlayoutInitialized, with: false)
        stub(for: \.isRecordingInitialized, with: false)
        stub(for: \.isMicrophoneMuted, with: false)
        stub(for: \.isStereoPlayoutEnabled, with: false)
        stub(for: \.isVoiceProcessingBypassed, with: false)
        stub(for: \.isVoiceProcessingEnabled, with: false)
        stub(for: \.isVoiceProcessingAGCEnabled, with: false)
        stub(for: \.prefersStereoPlayout, with: false)

        stub(for: .initAndStartRecording, with: 0)
        stub(for: .setMicrophoneMuted, with: 0)
        stub(for: .stopRecording, with: 0)
        stub(for: .reset, with: 0)
        stub(for: .initAndStartPlayout, with: 0)
        stub(for: .startPlayout, with: 0)
        stub(for: .stopPlayout, with: 0)
        stub(for: .startRecording, with: 0)
        stub(for: .refreshStereoPlayoutState, with: 0)
        stub(for: .setMuteMode, with: 0)
        stub(for: .setRecordingAlwaysPreparedMode, with: 0)
    }

    // MARK: - RTCAudioDeviceModuleControlling

    let microphoneMutedSubject: CurrentValueSubject<Bool, Never> = .init(false)

    var observer: (any RTCAudioDeviceModuleDelegate)?

    var isPlaying: Bool {
        self[dynamicMember: \.isPlaying]
    }

    var isRecording: Bool {
        self[dynamicMember: \.isRecording]
    }

    var isPlayoutInitialized: Bool {
        self[dynamicMember: \.isPlayoutInitialized]
    }

    var isRecordingInitialized: Bool {
        self[dynamicMember: \.isRecordingInitialized]
    }

    var isMicrophoneMuted: Bool {
        self[dynamicMember: \.isMicrophoneMuted]
    }

    var isStereoPlayoutEnabled: Bool {
        self[dynamicMember: \.isStereoPlayoutEnabled]
    }

    var isVoiceProcessingBypassed: Bool {
        get { self[dynamicMember: \.isVoiceProcessingBypassed] }
        set { stub(for: \.isVoiceProcessingBypassed, with: newValue) }
    }

    var isVoiceProcessingEnabled: Bool {
        self[dynamicMember: \.isVoiceProcessingEnabled]
    }

    var isVoiceProcessingAGCEnabled: Bool {
        self[dynamicMember: \.isVoiceProcessingAGCEnabled]
    }

    var prefersStereoPlayout: Bool {
        get { self[dynamicMember: \.prefersStereoPlayout] }
        set { stub(for: \.prefersStereoPlayout, with: newValue) }
    }

    func initAndStartRecording() -> Int {
        stubbedFunctionInput[.initAndStartRecording]?
            .append(.initAndStartRecording)
        return stubbedFunction[.initAndStartRecording] as? Int ?? 0
    }

    func setMicrophoneMuted(_ isMuted: Bool) -> Int {
        stubbedFunctionInput[.setMicrophoneMuted]?
            .append(.setMicrophoneMuted(isMuted))
        return stubbedFunction[.setMicrophoneMuted] as! Int
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

    func reset() -> Int {
        stubbedFunctionInput[.reset]?
            .append(.reset)
        return stubbedFunction[.reset] as! Int
    }

    func initAndStartPlayout() -> Int {
        stubbedFunctionInput[.initAndStartPlayout]?
            .append(.initAndStartPlayout)
        return stubbedFunction[.initAndStartPlayout] as! Int
    }

    func startPlayout() -> Int {
        stubbedFunctionInput[.startPlayout]?
            .append(.startPlayout)
        return stubbedFunction[.startPlayout] as! Int
    }

    func stopPlayout() -> Int {
        stubbedFunctionInput[.stopPlayout]?
            .append(.stopPlayout)
        return stubbedFunction[.stopPlayout] as! Int
    }

    func startRecording() -> Int {
        stubbedFunctionInput[.startRecording]?
            .append(.startRecording)
        return stubbedFunction[.startRecording] as! Int
    }

    func refreshStereoPlayoutState() {
        stubbedFunctionInput[.refreshStereoPlayoutState]?
            .append(.refreshStereoPlayoutState)
    }

    func setMuteMode(_ mode: RTCAudioEngineMuteMode) -> Int {
        stubbedFunctionInput[.setMuteMode]?
            .append(.setMuteMode(mode))
        return stubbedFunction[.setMuteMode] as! Int
    }

    func setRecordingAlwaysPreparedMode(_ alwaysPreparedRecording: Bool) -> Int {
        stubbedFunctionInput[.setRecordingAlwaysPreparedMode]?
            .append(.setRecordingAlwaysPreparedMode(alwaysPreparedRecording))
        return stubbedFunction[.setRecordingAlwaysPreparedMode] as! Int
    }
}
