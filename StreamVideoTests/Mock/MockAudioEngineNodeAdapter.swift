//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
@testable import StreamVideo

final class MockAudioEngineNodeAdapter: AudioEngineNodeAdapting, Mockable, @unchecked Sendable {
    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case installInputTap
        case uninstall
    }

    enum MockFunctionInputKey: Payloadable {
        case installInputTap(Int, UInt32)
        case uninstall(bus: Int)

        var payload: Any {
            switch self {
            case let .installInputTap(bus, bufferSize):
                return (bus, bufferSize)

            case let .uninstall(bus):
                return bus
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] =
        MockFunctionKey.allCases.reduce(into: [:]) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockAudioEngineNodeAdapter, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    init() {}

    // MARK: - AudioEngineNodeAdapting

    var subject: CurrentValueSubject<Float, Never>?

    func installInputTap(
        on node: AVAudioNode,
        format: AVAudioFormat,
        bus: Int,
        bufferSize: UInt32
    ) {
        stubbedFunctionInput[.installInputTap]?
            .append(
                .installInputTap(
                    bus, bufferSize
                )
            )
    }

    func uninstall(on bus: Int) {
        stubbedFunctionInput[.uninstall]?
            .append(.uninstall(bus: bus))
    }
}
