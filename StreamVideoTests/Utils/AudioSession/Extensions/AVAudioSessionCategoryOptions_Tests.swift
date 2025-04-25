//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class AVAudioSessionCategoryOptionsTests: XCTestCase, @unchecked Sendable {

    // MARK: - playAndRecord

    func test_playAndRecord_videoOnFalse_speakerOnFalse_appForegroundedFalse_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord(
                videoOn: false,
                speakerOn: false,
                appIsInForeground: false
            ),
            [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay
            ]
        )
    }

    func test_playAndRecord_videoOnTrue_speakerOnFalse_appForegroundedFalse_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord(
                videoOn: true,
                speakerOn: false,
                appIsInForeground: false
            ),
            [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay
            ]
        )
    }

    func test_playAndRecord_videoOnTrue_speakerOnTrue_appForegroundedFalse_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord(
                videoOn: true,
                speakerOn: true,
                appIsInForeground: false
            ),
            [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay
            ]
        )
    }

    func test_playAndRecord_videoOnTrue_speakerOnTrue_appForegroundedTrue_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord(
                videoOn: true,
                speakerOn: true,
                appIsInForeground: true
            ),
            [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay
            ]
        )
    }

    func test_playAndRecord_videoOnFalse_speakerOnTrue_appForegroundedTrue_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord(
                videoOn: false,
                speakerOn: true,
                appIsInForeground: true
            ),
            [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay,
                .defaultToSpeaker
            ]
        )
    }

    func test_playAndRecord_videoOnFalse_speakerOnFalse_appForegroundedTrue_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord(
                videoOn: false,
                speakerOn: false,
                appIsInForeground: true
            ),
            [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay
            ]
        )
    }

    func test_playAndRecord_videoOnTrue_speakerOnFalse_appForegroundedTrue_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord(
                videoOn: true,
                speakerOn: false,
                appIsInForeground: true
            ),
            [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay
            ]
        )
    }

    func test_playAndRecord_videoOnFalse_speakerOnTrue_appForegroundedFalse_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord(
                videoOn: false,
                speakerOn: true,
                appIsInForeground: false
            ),
            [
                .allowBluetooth,
                .allowBluetoothA2DP,
                .allowAirPlay
            ]
        )
    }

    // MARK: - playback
    
    func test_playback_whenAccessed_thenReturnsEmptyOptions() {
        XCTAssertEqual(AVAudioSession.CategoryOptions.playback, [])
    }
}
