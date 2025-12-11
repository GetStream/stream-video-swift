//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockAudioSession: AudioSessionProtocol, Mockable, @unchecked Sendable {
    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case setPrefersNoInterruptionsFromSystemAlerts
        case requestRecordPermission
        case addDelegate
        case removeDelegate
        case audioSessionDidActivate
        case audioSessionDidDeactivate
        case setActive
        case overrideOutputAudioPort
        case setConfiguration
        case setPreferredOutputNumberOfChannels
    }

    enum MockFunctionInputKey: Payloadable {
        case setPrefersNoInterruptionsFromSystemAlerts(Bool)
        case requestRecordPermission
        case addDelegate(RTCAudioSessionDelegate)
        case removeDelegate(RTCAudioSessionDelegate)
        case audioSessionDidActivate(AVAudioSession)
        case audioSessionDidDeactivate(AVAudioSession)
        case setActive(Bool)
        case overrideOutputAudioPort(AVAudioSession.PortOverride)
        case setConfiguration(RTCAudioSessionConfiguration)
        case setPreferredOutputNumberOfChannels(Int)

        var payload: Any {
            switch self {
            case let .setPrefersNoInterruptionsFromSystemAlerts(value):
                return value

            case .requestRecordPermission:
                return ()

            case let .addDelegate(delegate):
                return delegate

            case let .removeDelegate(delegate):
                return delegate

            case let .audioSessionDidActivate(audioSession):
                return audioSession

            case let .audioSessionDidDeactivate(audioSession):
                return audioSession

            case let .setActive(isActive):
                return isActive

            case let .overrideOutputAudioPort(port):
                return port

            case let .setConfiguration(configuration):
                return configuration

            case let .setPreferredOutputNumberOfChannels(value):
                return value
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] =
        MockFunctionKey.allCases.reduce(into: [:]) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockAudioSession, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - Init

    init() {
        stub(for: .requestRecordPermission, with: false)
    }

    // MARK: - AudioSessionProtocol

    var avSession: AVAudioSessionProtocol = MockAVAudioSession()

    var prefersNoInterruptionsFromSystemAlerts: Bool = false

    func setPrefersNoInterruptionsFromSystemAlerts(_ newValue: Bool) throws {
        stubbedFunctionInput[.setPrefersNoInterruptionsFromSystemAlerts]?
            .append(.setPrefersNoInterruptionsFromSystemAlerts(newValue))

        if let error = stubbedFunction[.setPrefersNoInterruptionsFromSystemAlerts] as? Error {
            throw error
        }

        prefersNoInterruptionsFromSystemAlerts = newValue
    }

    var isActive: Bool = false

    var isAudioEnabled: Bool = false

    var useManualAudio: Bool = false

    var category: String = ""

    var mode: String = ""

    var categoryOptions: AVAudioSession.CategoryOptions = []

    var recordPermissionGranted: Bool = false

    func requestRecordPermission() async -> Bool {
        stubbedFunctionInput[.requestRecordPermission]?
            .append(.requestRecordPermission)

        return stubbedFunction[.requestRecordPermission] as! Bool
    }

    var currentRoute: AVAudioSessionRouteDescription = .init()

    func add(_ delegate: any RTCAudioSessionDelegate) {
        stubbedFunctionInput[.addDelegate]?
            .append(.addDelegate(delegate))
    }

    func remove(_ delegate: any RTCAudioSessionDelegate) {
        stubbedFunctionInput[.removeDelegate]?
            .append(.removeDelegate(delegate))
    }

    func audioSessionDidActivate(_ audioSession: AVAudioSession) {
        stubbedFunctionInput[.audioSessionDidActivate]?
            .append(.audioSessionDidActivate(audioSession))
    }

    func audioSessionDidDeactivate(_ audioSession: AVAudioSession) {
        stubbedFunctionInput[.audioSessionDidDeactivate]?
            .append(.audioSessionDidDeactivate(audioSession))
    }

    func setActive(_ isActive: Bool) throws {
        stubbedFunctionInput[.setActive]?
            .append(.setActive(isActive))

        if let error = stubbedFunction[.setActive] as? Error {
            throw error
        }

        self.isActive = isActive
    }

    func perform(
        _ operation: (any AudioSessionProtocol) throws -> Void
    ) throws {
        try operation(self)
    }

    func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) throws {
        stubbedFunctionInput[.overrideOutputAudioPort]?
            .append(.overrideOutputAudioPort(port))

        if let error = stubbedFunction[.overrideOutputAudioPort] as? Error {
            throw error
        }
    }

    func setConfiguration(_ configuration: RTCAudioSessionConfiguration) throws {
        stubbedFunctionInput[.setConfiguration]?
            .append(.setConfiguration(configuration))

        if let error = stubbedFunction[.setConfiguration] as? Error {
            throw error
        }

        category = configuration.category
        mode = configuration.mode
        categoryOptions = configuration.categoryOptions
    }

    func setPreferredOutputNumberOfChannels(_ noOfChannels: Int) throws {
        stubbedFunctionInput[.setPreferredOutputNumberOfChannels]?
            .append(.setPreferredOutputNumberOfChannels(noOfChannels))

        if let error = stubbedFunction[.setPreferredOutputNumberOfChannels] as? Error {
            throw error
        }
    }
}
