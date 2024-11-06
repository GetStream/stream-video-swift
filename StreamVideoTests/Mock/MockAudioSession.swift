//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC

final class MockAudioSession: AudioSessionProtocol, Mockable {
    final class WeakBox<T: AnyObject> {
        weak var value: T?
        init(value: T?) { self.value = value }
    }

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    enum MockFunctionKey: CaseIterable {
        case add
        case setMode
        case setCategory
        case setActive
        case setConfiguration
        case overrideOutputAudioPort
        case updateConfiguration
        case requestRecordPermission
    }

    enum MockFunctionInputKey: Payloadable {
        case add(delegate: WeakBox<RTCAudioSessionDelegate>)
        case setMode(mode: String)
        case setCategory(category: String, categoryOptions: AVAudioSession.CategoryOptions)
        case setActive(value: Bool)
        case setConfiguration(value: RTCAudioSessionConfiguration)
        case overrideOutputAudioPort(value: AVAudioSession.PortOverride)
        case updateConfiguration
        case requestRecordPermission

        var payload: Any {
            switch self {
            case let .add(delegate):
                return delegate

            case let .setMode(mode):
                return mode

            case let .setCategory(category, categoryOptions):
                return (category, categoryOptions)

            case let .setActive(value):
                return value

            case let .setConfiguration(value):
                return value

            case let .overrideOutputAudioPort(value):
                return value

            case .updateConfiguration:
                return ()

            case .requestRecordPermission:
                return ()
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockAudioSession, T>, with value: T) { stubbedProperty[propertyKey(for: keyPath)] = value }
    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    // MARK: - AudioSessionProtocol

    var isActive: Bool = false

    var currentRoute: AVAudioSessionRouteDescription = .init()

    var category: String = ""

    var isUsingSpeakerOutput: Bool = false

    var isUsingExternalOutput: Bool = false

    var useManualAudio: Bool = false

    var isAudioEnabled: Bool = false

    func add(_ delegate: RTCAudioSessionDelegate) {
        stubbedFunctionInput[.add]?.append(.add(delegate: .init(value: delegate)))
    }

    func setMode(_ mode: String) throws {
        stubbedFunctionInput[.setMode]?.append(.setMode(mode: mode))
    }

    func setCategory(
        _ category: String,
        with categoryOptions: AVAudioSession.CategoryOptions
    ) throws {
        stubbedFunctionInput[.setCategory]?.append(
            .setCategory(
                category: category,
                categoryOptions: categoryOptions
            )
        )
    }

    func setActive(_ isActive: Bool) throws {
        stubbedFunctionInput[.setActive]?.append(.setActive(value: isActive))
    }

    func setConfiguration(_ configuration: RTCAudioSessionConfiguration) throws {
        stubbedFunctionInput[.setConfiguration]?.append(
            .setConfiguration(
                value: configuration
            )
        )
    }

    func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) throws {
        stubbedFunctionInput[.overrideOutputAudioPort]?.append(
            .overrideOutputAudioPort(value: port)
        )
    }

    func updateConfiguration(
        functionName: StaticString,
        file: StaticString,
        line: UInt,
        _ block: @escaping (AudioSessionProtocol) throws -> Void
    ) {
        do {
            try block(self)
            stubbedFunctionInput[.updateConfiguration]?.append(.updateConfiguration)
        } catch {
            /* No-op */
        }
    }

    func requestRecordPermission() async -> Bool {
        stubbedFunctionInput[.requestRecordPermission]?.append(.requestRecordPermission)
        return stubbedFunction[.requestRecordPermission] as? Bool ?? false
    }
}
