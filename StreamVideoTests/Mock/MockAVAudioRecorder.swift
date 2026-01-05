//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo

final class MockAVAudioRecorder: AVAudioRecorder, Mockable, @unchecked Sendable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = FunctionKey
        .allCases
        .reduce(into: [FunctionKey: [FunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockAVAudioRecorder, T>, with value: T) { stubbedProperty[propertyKey(for: keyPath)] = value }
    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case record
        case updateMeters
        case stop
    }

    enum MockFunctionInputKey: Payloadable {
        case record
        case updateMeters
        case stop

        var payload: Any {
            switch self {
            case .record:
                return ()

            case .updateMeters:
                return ()

            case .stop:
                return ()
            }
        }
    }

    static func build() throws -> MockAVAudioRecorder {
        let url = URL(fileURLWithPath: "/dev/null")
        let result = try MockAVAudioRecorder(url: url, settings: [:])
        result.stub(for: .record, with: true)
        return result
    }

    override func record() -> Bool {
        stubbedFunctionInput[.record]?.append(.record)
        return (stubbedFunction[.record] as? Bool) ?? super.record()
    }

    override func updateMeters() {
        stubbedFunctionInput[.updateMeters]?.append(.updateMeters)
    }

    override func stop() {
        stubbedFunctionInput[.stop]?.append(.stop)
    }
}
