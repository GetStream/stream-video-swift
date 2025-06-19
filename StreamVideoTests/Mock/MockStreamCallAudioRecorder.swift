//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo

final class MockStreamCallAudioRecorder: StreamCallAudioRecorder, @unchecked Sendable, Mockable {

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = FunctionKey.allCases
        .reduce(into: [FunctionKey: [MockFunctionInputKey]]()) { $0[$1] = [] }
    func stub<T>(for keyPath: KeyPath<MockStreamCallAudioRecorder, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) { stubbedFunction[function] = value }

    enum MockFunctionKey: Hashable, CaseIterable {
        case startRecording
        case stopRecording
    }

    enum MockFunctionInputKey: Payloadable {
        case startRecording(ignoreActiveCall: Bool)
        case stopRecording

        var payload: Any {
            switch self {
            case let .startRecording(ignoreActiveCall):
                return ignoreActiveCall
            case .stopRecording:
                return ()
            }
        }
    }

    var metersSubject: CurrentValueSubject<Float, Never> = .init(0.0)

    init() {
        super.init(filename: "mock_file")
        InjectedValues[\.callAudioRecorder] = self
    }

    override func startRecording(ignoreActiveCall: Bool = false) async {
        stubbedFunctionInput[.startRecording]?
            .append(.startRecording(ignoreActiveCall: ignoreActiveCall))
    }

    override func stopRecording() async {
        stubbedFunctionInput[.stopRecording]?.append(.stopRecording)
    }

    // Mock the metersPublisher
    override var metersPublisher: AnyPublisher<Float, Never> {
        metersSubject.eraseToAnyPublisher()
    }
}
