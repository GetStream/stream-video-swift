//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// This file is auto-generated. Do not edit.

import StreamCoreUI
import UIKit

extension VideoAppearance {
    /// VideoAppearance color tokens derived from StreamCoreUI.
    public final class Colors {
        private let colors: DesignSystemTokens.Colors

        // MARK: - Control

        public lazy var controlAcceptCallButtonBackground: UIColor =
            colors.accentSuccess
        public lazy var controlAcceptCallButtonText: UIColor =
            colors.textOnAccent
        public lazy var controlCallControlErrorBadgeBackground: UIColor =
            colors.accentWarning
        public lazy var controlCallControlErrorBadgeText: UIColor = UIColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 1
        )
        public lazy var controlDeclineCallButtonBackground: UIColor =
            colors.accentError
        public lazy var controlDeclineCallButtonText: UIColor =
            colors.textOnAccent

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
    }
}
