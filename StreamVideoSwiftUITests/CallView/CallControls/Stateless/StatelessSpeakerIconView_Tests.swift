//
//  StatelessSpeakerIconView_Tests.swift
//  StreamVideoSwiftUITests
//
//  Created by Ilias Pavlidakis on 1/5/24.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

final class StatelessSpeakerIconView_Tests: StreamVideoUITestCase {

    // MARK: - Appearance

    @MainActor
    func test_appearance_cameraOn_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                cameraOn: true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_cameraOff_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                cameraOn: false
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_audioDefaultDeviceSpeaker_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                audioDefaultDevice: .speaker
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_audioDefaultDeviceEarpiece_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                audioDefaultDevice: .earpiece
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_audioDefaultDeviceUnknown_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                audioDefaultDevice: .unknown
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    // MARK: Private helpers

    @MainActor
    private func makeSubject(
        cameraOn: Bool = false,
        audioDefaultDevice: AudioSettings.DefaultDevice = .unknown,
        actionHandler: (() -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> StatelessSpeakerIconView {
        let call = try XCTUnwrap(
            streamVideoUI?.streamVideo.call(
                callType: .default,
                callId: "test"
            ),
            file: file,
            line: line
        )
        call.state.update(
            from: .dummy(
                settings: .dummy(
                    audio: .dummy(defaultDevice: audioDefaultDevice),
                    video: .dummy(cameraDefaultOn: cameraOn)
                )
            )
        )

        return .init(call: call, actionHandler: actionHandler)
    }
}



