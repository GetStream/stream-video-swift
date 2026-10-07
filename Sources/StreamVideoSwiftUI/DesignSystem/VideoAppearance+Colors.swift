//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// This file is auto-generated. Do not edit.

import StreamCoreUI
import UIKit

extension VideoAppearance {
    /// VideoAppearance color tokens derived from StreamCoreUI.
    ///
    /// Shared colors from `DesignSystemTokens.Colors` are readable through
    /// this type too, so `colors.textPrimary` resolves to the shared token.
    @dynamicMemberLookup
    public final class Colors {
        private let colors: DesignSystemTokens.Colors

        // MARK: - Control

        public lazy var controlAcceptCallButtonBackground: UIColor =
            colors.accentSuccess
        public lazy var callControlButtonText: UIColor = .white
        public lazy var controlAcceptCallButtonText: UIColor = callControlButtonText
        public lazy var controlCallControlErrorBadgeBackground: UIColor =
            colors.accentWarning
        public lazy var controlCallControlErrorBadgeText: UIColor = .black
        public lazy var controlDeclineCallButtonBackground: UIColor =
            colors.accentError
        public lazy var controlDeclineCallButtonText: UIColor = callControlButtonText

        // MARK: - Indicator

        public lazy var indicatorConnectionQualityFair: UIColor =
            colors.accentWarning
        public lazy var indicatorConnectionQualityGreat: UIColor =
            colors.accentSuccess
        public lazy var indicatorConnectionQualityPoor: UIColor =
            colors.accentError
        public lazy var indicatorMicrophoneLevelBarActive: UIColor =
            colors.palette.brand400
        public lazy var indicatorMicrophoneLevelBarInactive: UIColor =
            colors.palette.chrome200
        public lazy var indicatorSoundIndicatorSpeaking: UIColor =
            colors.palette.brand400

        public init(tokens: DesignSystemTokens = DesignSystemTokens()) {
            colors = tokens.colors
        }

        /// Reads a shared color from `DesignSystemTokens.Colors`.
        public subscript<T>(dynamicMember keyPath: KeyPath<DesignSystemTokens.Colors, T>) -> T {
            colors[keyPath: keyPath]
        }
    }
}
