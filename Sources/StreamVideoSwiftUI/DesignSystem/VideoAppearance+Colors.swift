//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import UIKit

/// Video-specific color tokens, derived from ``DesignSystemTokens/Colors``.
///
/// Read them on the Video appearance:
/// `videoAppearance.colors.indicatorSpeaking`.
extension VideoAppearance {
    public final class Colors {
        private let colors: DesignSystemTokens.Colors

        // MARK: - Control

        public lazy var controlAcceptCallBackground: UIColor = colors
            .accentSuccess
        public lazy var controlAcceptCallText: UIColor = colors.textOnAccent
        public lazy var controlVideoBackgroundControlBackground: UIColor = colors
            .backgroundCoreSurfaceSubtle
        public lazy var controlVideoBackgroundControlBackgroundSelected: UIColor =
            colors.accentPrimary
        public lazy var controlVideoBackgroundControlText: UIColor = colors
            .textPrimary
        public lazy var controlVideoBackgroundControlTextSelected: UIColor =
            colors.textOnAccent

        // MARK: - Indicator

        public lazy var indicatorFair: UIColor = colors.accentWarning
        public lazy var indicatorGreat: UIColor = colors.accentSuccess
        public lazy var indicatorPoor: UIColor = colors.accentError
        public lazy var indicatorSpeaking: UIColor = colors.palette.brand300

        // MARK: - Label

        public lazy var labelBackgroundNeutral: UIColor = colors.palette.chrome150
        public lazy var labelBackgroundPrimary: UIColor = colors.palette.brand150
        public lazy var labelTextNeutral: UIColor = colors.textPrimary
        public lazy var labelTextPrimary: UIColor = colors.palette.brand900

        public init(tokens: DesignSystemTokens = DesignSystemTokens()) {
            self.colors = tokens.colors
        }
    }
}
