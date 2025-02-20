//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

import AVFoundation
import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamRTCAudioSessionTests: XCTestCase, @unchecked Sendable {

    private lazy var subject: StreamRTCAudioSession! = .init()
    private lazy var rtcAudioSession: RTCAudioSession! = .sharedInstance()
    private var cancellables: Set<AnyCancellable>! = []

    override func tearDown() async throws {
        cancellables = nil
        subject = nil
        rtcAudioSession = nil
        try await super.tearDown()
    }

    // MARK: - Initialization

    func test_init_setsInitialState() {
        XCTAssertEqual(subject.state.category.rawValue, rtcAudioSession.category)
        XCTAssertEqual(subject.state.mode.rawValue, rtcAudioSession.mode)
        XCTAssertEqual(subject.state.options, rtcAudioSession.categoryOptions)
        XCTAssertEqual(subject.state.overrideOutputPort, .none)
    }

    // MARK: - setCategory

    func test_setCategory_whenNoChangesNeeded_thenDoesNotUpdateState() async throws {
        let initialState = subject.state

        try await subject.setCategory(
            initialState.category,
            mode: initialState.mode,
            with: initialState.options
        )

        XCTAssertEqual(subject.state, initialState)
    }

    func test_setCategory_whenCategoryChanges_thenUpdatesState() async throws {
        let newCategory: AVAudioSession.Category = .playback
        let initialState = subject.state

        try await subject.setCategory(
            newCategory,
            mode: initialState.mode,
            with: initialState.options
        )

        XCTAssertEqual(subject.state.category, newCategory)
        XCTAssertEqual(subject.state.mode, initialState.mode)
        XCTAssertEqual(subject.state.options, initialState.options)
    }

    func test_setCategory_whenModeChanges_thenUpdatesState() async throws {
        let newMode: AVAudioSession.Mode = .videoChat
        let initialState = subject.state

        try await subject.setCategory(
            initialState.category,
            mode: newMode,
            with: initialState.options
        )

        XCTAssertEqual(subject.state.category, initialState.category)
        XCTAssertEqual(subject.state.mode, newMode)
        XCTAssertEqual(subject.state.options, initialState.options)
    }

    func test_setCategory_whenOptionsChange_thenUpdatesState() async throws {
        let newOptions: AVAudioSession.CategoryOptions = .mixWithOthers
        let initialState = subject.state

        try await subject.setCategory(
            initialState.category,
            mode: initialState.mode,
            with: newOptions
        )

        XCTAssertEqual(subject.state.category, initialState.category)
        XCTAssertEqual(subject.state.mode, initialState.mode)
        XCTAssertEqual(subject.state.options, newOptions)
    }

    func test_setCategory_thenUpdatesWebRTCConfiguration() async throws {
        let newOptions: AVAudioSession.CategoryOptions = .mixWithOthers

        try await subject.setCategory(
            .soloAmbient,
            mode: .default,
            with: newOptions
        )

        let webRTCConfiguration = RTCAudioSessionConfiguration.webRTC()
        XCTAssertEqual(subject.state.category.rawValue, webRTCConfiguration.category)
        XCTAssertEqual(subject.state.mode.rawValue, webRTCConfiguration.mode)
        XCTAssertEqual(subject.state.options, webRTCConfiguration.categoryOptions)
    }

    // MARK: - overrideOutputAudioPort

    func test_overrideOutputAudioPort_whenCategoryIsNotPlayAndRecord_thenDoesNotUpdateState() async throws {
        try await subject.setCategory(.playback, mode: .default, with: [])
        let initialState = subject.state

        try await subject.overrideOutputAudioPort(.speaker)

        XCTAssertEqual(subject.state, initialState)
    }

    func test_overrideOutputAudioPort_whenPortIsSameAsCurrent_thenDoesNotUpdateState() async throws {
        try await subject.setCategory(.playAndRecord, mode: .default, with: [])
        try await subject.overrideOutputAudioPort(.speaker)
        let initialState = subject.state

        try await subject.overrideOutputAudioPort(.speaker)

        XCTAssertEqual(subject.state, initialState)
    }

    func test_overrideOutputAudioPort_whenValidChange_thenUpdatesState() async throws {
        try await subject.setCategory(.playAndRecord, mode: .default, with: [])

        try await subject.overrideOutputAudioPort(.speaker)

        XCTAssertEqual(subject.state.overrideOutputPort, .speaker)
    }

    // MARK: - Properties

    func test_isActive_returnsSourceValue() {
        XCTAssertEqual(subject.isActive, rtcAudioSession.isActive)
    }

    func test_currentRoute_returnsSourceValue() {
        XCTAssertEqual(subject.currentRoute, rtcAudioSession.currentRoute)
    }

    func test_category_returnsStateCategory() {
        XCTAssertEqual(subject.category, subject.state.category)
    }

    func test_useManualAudio_whenSet_updatesSourceValue() {
        subject.useManualAudio = true
        XCTAssertTrue(rtcAudioSession.useManualAudio)

        subject.useManualAudio = false
        XCTAssertFalse(rtcAudioSession.useManualAudio)
    }

    func test_isAudioEnabled_whenSet_updatesSourceValue() {
        subject.isAudioEnabled = true
        XCTAssertTrue(rtcAudioSession.isAudioEnabled)

        subject.isAudioEnabled = false
        XCTAssertFalse(rtcAudioSession.isAudioEnabled)
    }
}
