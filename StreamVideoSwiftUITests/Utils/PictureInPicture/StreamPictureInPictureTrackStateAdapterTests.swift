//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import XCTest

final class StreamPictureInPictureTrackStateAdapterTests: XCTestCase, @unchecked Sendable {

    private var factory: PeerConnectionFactory! = .build(audioProcessingModule: MockAudioProcessingModule.shared)
    private var adapter: StreamPictureInPictureTrackStateAdapter! = .init()

    private lazy var trackA: RTCVideoTrack! = factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))
    private lazy var trackB: RTCVideoTrack! = factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))

    // MARK: - Lifecycle

    override func tearDown() {
        trackA?.isEnabled = false
        trackB?.isEnabled = false
        adapter = nil
        factory = nil
        super.tearDown()
    }

    // MARK: - enabled

    @MainActor
    func test_enabled_enablesTheActiveTrack() async throws {
        trackA.isEnabled = false
        adapter.activeTrack = trackA

        adapter.isEnabled = true

        await fulfillment { self.trackA.isEnabled == true }
    }

    @MainActor
    func test_enabled_whenTheActiveTrackChanges_disablesTheOldTrack() async throws {
        trackA.isEnabled = true
        adapter.activeTrack = trackA
        trackB.isEnabled = false

        adapter.isEnabled = true
        adapter.activeTrack = trackB

        await fulfillment { self.trackA.isEnabled == false }
    }

    // MARK: - disabled

    @MainActor
    func test_disabled_doesNotChangeTheEnableForTheActiveTrack() async throws {
        trackA.isEnabled = false
        adapter.activeTrack = trackA

        adapter.isEnabled = false

        await fulfillment { self.trackA.isEnabled == false }
    }

    @MainActor
    func test_disabled_whenTheActiveTrackChanges_doesNotDisableTheOldTrack() async throws {
        trackA.isEnabled = true
        adapter.activeTrack = trackA
        trackB.isEnabled = false
        adapter.isEnabled = false

        adapter.activeTrack = trackB

        await fulfillment { self.trackA.isEnabled == true }
    }
}
