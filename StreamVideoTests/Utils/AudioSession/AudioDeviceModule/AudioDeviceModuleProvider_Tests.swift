//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class AudioDeviceModuleProvider_Tests: XCTestCase, @unchecked Sendable {

    func test_audioDeviceModule_returnsResolvedInstance() {
        let source = MockRTCAudioDeviceModule()
        let module = AudioDeviceModule(source)
        let subject = AudioDeviceModuleProvider { module }

        XCTAssertTrue(subject.audioDeviceModule() === module)
    }

    func test_audioDeviceModule_resolvesOnEachCall() {
        let source = MockRTCAudioDeviceModule()
        let calls = CallCount()
        let module = AudioDeviceModule(source)
        let subject = AudioDeviceModuleProvider {
            calls.value += 1
            return module
        }

        _ = subject.audioDeviceModule()
        _ = subject.audioDeviceModule()

        XCTAssertEqual(calls.value, 2)
    }
}

private final class CallCount: @unchecked Sendable {
    var value = 0
}
