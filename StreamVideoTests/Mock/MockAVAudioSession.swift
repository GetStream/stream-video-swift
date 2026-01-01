//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import StreamWebRTC

final class MockAVAudioSession: AVAudioSessionProtocol, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    /// Defines the "functions" or property accesses we want to track or stub.
    enum MockFunctionKey: CaseIterable {
        case setCategory
        case setOverrideOutputAudioPort
        case setIsActive
    }

    /// Defines typed payloads passed along with tracked function calls.
    enum MockFunctionInputKey: Payloadable {
        case setCategory(
            category: AVAudioSession.Category,
            mode: AVAudioSession.Mode,
            options: AVAudioSession.CategoryOptions
        )
        case setOverrideOutputAudioPort(value: AVAudioSession.PortOverride)

        case setIsActive(Bool)

        // Return an untyped payload for storage in the base Mockable dictionary.
        var payload: Any {
            switch self {
            case let .setCategory(category, mode, options):
                return (category, mode, options)

            case let .setOverrideOutputAudioPort(value):
                return value

            case let .setIsActive(value):
                return value
            }
        }
    }

    // MARK: - Mockable Storage

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic
    var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockAVAudioSession, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - AVAudioSessionProtocol

    /// Sets the audio category, mode, and options.
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        with categoryOptions: AVAudioSession.CategoryOptions
    ) throws {
        record(
            .setCategory,
            input: .setCategory(
                category: category,
                mode: mode,
                options: categoryOptions
            )
        )
        if let error = stubbedFunction[.setCategory] as? Error {
            throw error
        }
    }

    /// Overrides the audio output port.
    func setOverrideOutputAudioPort(_ port: AVAudioSession.PortOverride) throws {
        record(
            .setOverrideOutputAudioPort,
            input: .setOverrideOutputAudioPort(value: port)
        )
        if let error = stubbedFunction[.setOverrideOutputAudioPort] as? Error {
            throw error
        }
    }

    func setIsActive(_ active: Bool) throws {
        record(
            .setIsActive,
            input: .setIsActive(active)
        )
        if let error = stubbedFunction[.setIsActive] as? Error {
            throw error
        }
    }

    // MARK: - Helpers

    /// Tracks calls to a specific function/property in the mock.
    private func record(
        _ function: FunctionKey,
        input: FunctionInputKey? = nil
    ) {
        if let input {
            stubbedFunctionInput[function]?.append(input)
        } else {
            // Still record the call, but with no input
            stubbedFunctionInput[function]?.append(contentsOf: [])
        }
    }
}
