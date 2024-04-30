//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest  
@preconcurrency import StreamWebRTC
@testable import StreamVideo
@testable import StreamVideoSwiftUI

@MainActor
final class StreamPictureInPictureTrackStateAdapterTests: XCTestCase {

    private var factory: PeerConnectionFactory! = .init(audioProcessingModule: MockAudioProcessingModule())
    private var adapter: StreamPictureInPictureTrackStateAdapter! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        factory = nil
        adapter = nil
        super.tearDown()
    }

    // MARK: - enabled

    func test_enabled_enablesTheActiveTrack() async throws {
        let activeTrack = await makeVideoTrack()
        activeTrack.isEnabled = false
        adapter.activeTrack = activeTrack

        adapter.isEnabled = true

        try await XCTAssertWithDelay(activeTrack.isEnabled)
    }

    func test_enabled_whenTheActiveTrackChanges_disablesTheOldTrack() async throws {
        let activeTrack = await makeVideoTrack()
        activeTrack.isEnabled = true
        adapter.activeTrack = activeTrack
        let newActiveTrack = await makeVideoTrack()
        newActiveTrack.isEnabled = false
        adapter.isEnabled = true

        adapter.activeTrack = newActiveTrack

        try await XCTAssertWithDelay(newActiveTrack.isEnabled)
        XCTAssertFalse(activeTrack.isEnabled)
    }

    // MARK: - disabled

    func test_disabled_doesNotChangeTheEnableForTheActiveTrack() async throws {
        let activeTrack = await makeVideoTrack()
        activeTrack.isEnabled = false
        adapter.activeTrack = activeTrack

        adapter.isEnabled = false

        try await XCTAssertWithDelay(!activeTrack.isEnabled)
    }

    func test_disabled_whenTheActiveTrackChanges_doesNotDisableTheOldTrack() async throws {
        let activeTrack = await makeVideoTrack()
        activeTrack.isEnabled = true
        adapter.activeTrack = activeTrack
        let newActiveTrack = await makeVideoTrack()
        newActiveTrack.isEnabled = false
        adapter.isEnabled = false

        adapter.activeTrack = newActiveTrack

        try await XCTAssertWithDelay(activeTrack.isEnabled)
    }

    // MARK: - Private Helpers

    private func makeVideoTrack() async -> RTCVideoTrack {
        let videoSource = await factory.makeVideoSource(forScreenShare: false)
        return await factory.makeVideoTrack(source: videoSource)
    }
}
