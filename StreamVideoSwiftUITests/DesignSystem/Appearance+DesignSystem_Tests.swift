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

    // MARK: - Cascade

    func test_sharedTokenOverriddenBeforeFirstRead_videoColorUsesOverride() {
        let tokens = DesignSystemTokens()
        tokens.colors.palette.brand300 = .magenta
        subject = VideoAppearance(tokens: tokens)

        XCTAssertEqual(subject.colors.indicatorSpeaking, .magenta)
    }

    func test_videoColorOverridden_readsBackOverride() {
        subject.colors.indicatorSpeaking = .magenta

        XCTAssertEqual(subject.colors.indicatorSpeaking, .magenta)
    }

    func test_colorsInit_withoutTokens_usesDefaultDesignSystemTokens() {
        let colors = VideoAppearance.Colors()
        let expected = DesignSystemTokens().colors.palette.brand300

        assertEqualDynamicColor(colors.indicatorSpeaking, expected)
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
