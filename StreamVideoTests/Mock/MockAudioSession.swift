//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import StreamWebRTC

final class MockAudioSession: AudioSessionProtocol, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    /// Defines the "functions" or property accesses we want to track or stub.
    enum MockFunctionKey: CaseIterable {
        case setCategory
        case setActive
        case overrideOutputAudioPort
        case requestRecordPermission
    }

    /// Defines typed payloads passed along with tracked function calls.
    enum MockFunctionInputKey: Payloadable {
        case setCategory(
            category: AVAudioSession.Category,
            mode: AVAudioSession.Mode,
            options: AVAudioSession.CategoryOptions
        )
        case setActive(value: Bool)
        case overrideOutputAudioPort(value: AVAudioSession.PortOverride)
        case requestRecordPermission

        // Return an untyped payload for storage in the base Mockable dictionary.
        var payload: Any {
            switch self {
            case let .setCategory(category, mode, options):
                return (category, mode, options)

            case let .setActive(value):
                return value

            case let .overrideOutputAudioPort(value):
                return value

            case .requestRecordPermission:
                return ()
            }
        }
    }

    // MARK: - Mockable Storage

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic
    var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockAudioSession, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - AudioSessionProtocol

    let eventSubject = PassthroughSubject<AudioSessionEvent, Never>()

    init() {
        stub(for: \.eventPublisher, with: eventSubject.eraseToAnyPublisher())
        stub(for: \.isActive, with: false)
        stub(for: \.currentRoute, with: AVAudioSessionRouteDescription())
        stub(for: \.category, with: AVAudioSession.Category.soloAmbient)
        stub(for: \.useManualAudio, with: false)
        stub(for: \.isAudioEnabled, with: false)
    }

    /// Publishes audio session-related events.
    var eventPublisher: AnyPublisher<AudioSessionEvent, Never> {
        get { self[dynamicMember: \.eventPublisher] }
        set { stub(for: \.eventPublisher, with: newValue) }
    }

    /// Indicates whether the audio session is active.
    var isActive: Bool {
        get { self[dynamicMember: \.isActive] }
        set { stub(for: \.isActive, with: newValue) }
    }

    /// The current audio route for the session.
    var currentRoute: AVAudioSessionRouteDescription {
        get { self[dynamicMember: \.currentRoute] }
        set { stub(for: \.currentRoute, with: newValue) }
    }

    /// The current audio session category.
    var category: AVAudioSession.Category {
        get { self[dynamicMember: \.category] }
        set { stub(for: \.category, with: newValue) }
    }

    /// A Boolean value indicating if manual audio routing is used.
    var useManualAudio: Bool {
        get { self[dynamicMember: \.useManualAudio] }
        set { stub(for: \.useManualAudio, with: newValue) }
    }

    /// A Boolean value indicating if audio is enabled.
    var isAudioEnabled: Bool {
        get { self[dynamicMember: \.isAudioEnabled] }
        set { stub(for: \.isAudioEnabled, with: newValue) }
    }

    /// Sets the audio category, mode, and options.
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        with categoryOptions: AVAudioSession.CategoryOptions
    ) async throws {
        record(.setCategory, input: .setCategory(
            category: category,
            mode: mode,
            options: categoryOptions
        ))
        if let error = stubbedFunction[.setCategory] as? Error {
            throw error
        }
    }

    /// Activates or deactivates the audio session.
    func setActive(_ isActive: Bool) async throws {
        record(.setActive, input: .setActive(value: isActive))
        if let error = stubbedFunction[.setActive] as? Error {
            throw error
        }
    }

    /// Overrides the audio output port.
    func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) async throws {
        record(.overrideOutputAudioPort, input: .overrideOutputAudioPort(value: port))
        if let error = stubbedFunction[.overrideOutputAudioPort] as? Error {
            throw error
        }
    }

    /// Requests permission to record audio.
    func requestRecordPermission() async -> Bool {
        record(.requestRecordPermission, input: .requestRecordPermission)
        return (stubbedFunction[.requestRecordPermission] as? Bool) ?? false
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
