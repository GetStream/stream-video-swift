//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import UIKit
import XCTest

final class Appearance_DesignSystem_Tests: XCTestCase, @unchecked Sendable {

    private lazy var subject: VideoAppearance! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Isolated instance

    func test_init_usesItsOwnTokensAndColors() {
        let other = VideoAppearance()

        XCTAssertFalse(subject.tokens === other.tokens)
        XCTAssertFalse(subject.colors === other.colors)
    }

    func test_init_sharedTokens_areTheSameInstance() {
        let tokens = DesignSystemTokens()
        let video = VideoAppearance(tokens: tokens)
        let other = VideoAppearance(tokens: tokens)

        XCTAssertTrue(video.tokens === tokens)
        XCTAssertTrue(other.tokens === tokens)
    }

    // MARK: - Forwarding

    func test_tokens_colorWrite_readsBack() {
        subject.tokens.colors.palette.brand500 = .magenta

        XCTAssertEqual(subject.tokens.colors.palette.brand500, .magenta)
    }

    func test_tokens_layoutWrite_readsBack() {
        subject.tokens.layout.spacingMd = 99

        XCTAssertEqual(subject.tokens.layout.spacingMd, 99)
    }

    func test_tokens_fontWrite_readsBack() {
        let custom = Font.system(size: 99)
        subject.tokens.fonts.body = custom

        XCTAssertEqual(subject.tokens.fonts.body, custom)
    }

    // MARK: - Cascade

    func test_sharedTokenOverriddenBeforeFirstRead_videoColorUsesOverride() {
        let tokens = DesignSystemTokens()
        tokens.colors.palette.brand400 = .magenta
        subject = VideoAppearance(tokens: tokens)

        XCTAssertEqual(
            subject.colors.indicatorSoundIndicatorSpeaking,
            .magenta
        )
    }

    func test_videoColorOverridden_readsBackOverride() {
        subject.colors.indicatorSoundIndicatorSpeaking = .magenta

        XCTAssertEqual(
            subject.colors.indicatorSoundIndicatorSpeaking,
            .magenta
        )
    }

    func test_colorsInit_withoutTokens_usesDefaultDesignSystemTokens() {
        let colors = VideoAppearance.Colors()
        let expected = DesignSystemTokens().colors.palette.brand400

        assertEqualDynamicColor(
            colors.indicatorSoundIndicatorSpeaking,
            expected
        )
    }

    // MARK: - Sounds

    func test_init_withoutSounds_usesDefaultSounds() {
        XCTAssertEqual(subject.sounds.bundle, .streamVideoUI)
        XCTAssertEqual(subject.sounds.incomingCallSound.fileName, "incoming.m4a")
        XCTAssertEqual(subject.sounds.outgoingCallSound.fileName, "outgoing.m4a")
    }

    func test_init_withSounds_storesSameInstance() {
        let sounds = Sounds()

        subject = VideoAppearance(sounds: sounds)

        XCTAssertTrue(subject.sounds === sounds)
    }

    func test_injectedValues_whenVideoAppearanceIsSet_returnsSameInstance() {
        let previous = InjectedValues[\.videoAppearance]
        defer { InjectedValues[\.videoAppearance] = previous }

        InjectedValues[\.videoAppearance] = subject

        XCTAssertTrue(InjectedValues[\.videoAppearance] === subject)
    }

    // MARK: - Shared color lookup

    func test_colors_sharedToken_readsFromTokens() {
        subject.tokens.colors.textPrimary = .magenta

        XCTAssertEqual(subject.colors.textPrimary, .magenta)
    }

    func test_colors_sharedPalette_readsFromTokens() {
        subject.tokens.colors.palette.brand500 = .magenta

        XCTAssertEqual(subject.colors.palette.brand500, .magenta)
    }

    // MARK: - Injected keys

    func test_injectedColors_returnsVideoAppearanceColors() {
        withInjectedSubject {
            XCTAssertTrue(InjectedValues[\.colors] === subject.colors)
        }
    }

    func test_injectedColors_whenSet_updatesVideoAppearance() {
        let colors = VideoAppearance.Colors()

        withInjectedSubject {
            InjectedValues[\.colors] = colors

            XCTAssertTrue(subject.colors === colors)
        }
    }

    func test_injectedImages_returnsVideoAppearanceImages() {
        withInjectedSubject {
            XCTAssertTrue(InjectedValues[\.images] === subject.images)
        }
    }

    func test_injectedFonts_returnsTokenFonts() {
        withInjectedSubject {
            XCTAssertTrue(InjectedValues[\.fonts] === subject.tokens.fonts)
        }
    }

    func test_injectedLayout_returnsTokenLayout() {
        withInjectedSubject {
            XCTAssertTrue(InjectedValues[\.layout] === subject.tokens.layout)
        }
    }

    private func withInjectedSubject(_ body: () -> Void) {
        let previous = InjectedValues[\.videoAppearance]
        defer { InjectedValues[\.videoAppearance] = previous }
        InjectedValues[\.videoAppearance] = subject
        body()
    }

    // Dynamic `UIColor(light:dark:)` instances are not `==` even when they
    // resolve to the same pair, so compare the resolved styles instead.
    private func assertEqualDynamicColor(
        _ lhs: UIColor,
        _ rhs: UIColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        XCTAssertEqual(
            lhs.resolvedColor(with: light),
            rhs.resolvedColor(with: light),
            file: file,
            line: line
        )
        XCTAssertEqual(
            lhs.resolvedColor(with: dark),
            rhs.resolvedColor(with: dark),
            file: file,
            line: line
        )
    }
}
