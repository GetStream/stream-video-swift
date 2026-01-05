//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

final class MockAudioFilter: AudioFilter, Mockable {

    // MARK: - Mockable

    enum FunctionKey: Hashable, CaseIterable {
        case initialize
        case applyEffect
        case release
    }

    enum FunctionInputKey: Payloadable {
        case initialize(sampleRate: Int, channels: Int)
        case applyEffect(channels: Int, bands: Int, frames: Int)
        case release

        var payload: Any {
            switch self {
            case let .initialize(sampleRate, channels):
                return (sampleRate, channels)
            case let .applyEffect(channels, bands, frames):
                return (channels, bands, frames)
            case .release:
                return ()
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }

    func stub<T>(for keyPath: KeyPath<MockAudioFilter, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    // MARK: - AudioFilter

    struct InitParams: Equatable { let sampleRate: Int; let channels: Int }

    let id: String

    private(set) var initializedParams: InitParams?
    private(set) var releaseCount: Int = 0
    private(set) var applyCount: Int = 0

    init(id: String) { self.id = id }

    func initialize(sampleRate: Int, channels: Int) {
        initializedParams = .init(sampleRate: sampleRate, channels: channels)
        stubbedFunctionInput[.initialize]?.append(.initialize(sampleRate: sampleRate, channels: channels))
    }

    func applyEffect(to audioBuffer: inout RTCAudioBuffer) {
        applyCount += 1
        stubbedFunctionInput[.applyEffect]?.append(
            .applyEffect(
                channels: audioBuffer.channels,
                bands: audioBuffer.bands,
                frames: audioBuffer.frames
            )
        )
    }

    func release() {
        releaseCount += 1
        stubbedFunctionInput[.release]?.append(.release)
    }
}
