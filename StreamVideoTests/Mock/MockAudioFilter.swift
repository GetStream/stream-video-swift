//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockAudioFilter: AudioFilter, Mockable, @unchecked Sendable {
    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case applyEffect
    }

    enum MockFunctionInputKey: Payloadable {
        case applyEffect(RTCAudioBuffer)

        var payload: Any {
            switch self {
            case let .applyEffect(input):
                return input
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = MockAudioFilter.initialStubbedFunctionInput

    var id: String = .unique

    func applyEffect(to audioBuffer: inout RTCAudioBuffer) {
        record(.applyEffect, input: .applyEffect(audioBuffer))
    }
}
