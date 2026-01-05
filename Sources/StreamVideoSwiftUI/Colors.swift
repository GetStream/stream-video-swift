//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// Provides the colors used throughout the SDK.
public struct Colors {
    
    public init() { /* Public init. */ }
 
    public var text = Color(.streamBlack)
    public var accentRed = Color(.streamAccentRed)
    public var accentGreen = Color(.streamAccentGreen)
    public var accentBlue = Color(.streamAccentBlue)
    public var tintColor = Color.accentColor
    public var lightGray = Color(red: 180 / 255.0, green: 197 / 255.0, blue: 205 / 255.0)
    public var secondaryButton = Color(.streamGray)
    public var hangUpIconColor = Color(.systemRed)
    public var textInverted = Color(.streamWhite)
    public var onlineIndicatorColor = Color(.streamAccentGreen)
    public var whiteSmoke = Color(.streamWhiteSmoke)
    public var white = Color(.streamWhiteStatic)
    public var background: UIColor = .streamWhiteSnow
    public var background1: UIColor = .streamWhiteSmoke
    public var textLowEmphasis: UIColor = .streamGrayDisabledText
    public var callBackground: UIColor = .streamDarkBackground
    public var participantBackground: UIColor = .streamParticipantBackground
    public var lobbyBackground: Color = Color(.streamWaitingRoomBackground)
    public var lobbySecondaryBackground: Color = Color(.streamWaitingRoomSecondaryBackground)
    public var primaryButtonBackground: Color = Color(.streamAccentBlue)
    public var callPulsingColor = Color(.streamPulsingColor)
    public var callControlsBackground = Color(.streamCallControlsBackground)
    public var livestreamBackground = Color(.streamOverlay)
    public var livestreamCallControlsColor = Color(.streamWhiteStatic)
    public var livestreamText = Color(.streamBlack)
    public var participantSpeakingHighlightColor = Color(.streamAccentBlue).opacity(0.7)
    public var participantInfoBackgroundColor = Color(.streamOverlayDarkStatic)
    public var callDurationColor: UIColor = .streamWhiteStatic
    public var goodConnectionQualityIndicatorColor = Color(.streamAccentGreen)
    public var badConnectionQualityIndicatorColor = Color(.streamAccentRed)
    public var activeSecondaryCallControl = Color(.streamAccentBlue)
    public var inactiveCallControl = Color(.streamAccentRed)
}

// Those colors are default defined stream constants, which are fallback values if you don't implement your color theme.
// There is this static method `mode(_ light:, lightAlpha:, _ dark:, darkAlpha:)` which can help you in a great way with
// implementing dark mode support.
private extension UIColor {
    /// This is color palette used by design team.
    /// If you see any color not from this list in figma, point it out to anyone in design team.
    static let streamBlack = mode(0x000000, 0xffffff)
    static let streamGray = mode(0x7a7a7a, 0x7a7a7a)
    static let streamGrayGainsboro = mode(0xdbdbdb, 0x2d2f2f)
    static let streamGrayWhisper = mode(0xecebeb, 0x1c1e22)
    static let streamDarkGray = mode(0x7a7a7a, 0x7a7a7a)
    static let streamWhiteSmoke = mode(0xf2f2f2, 0x13151b)
    static let streamWhiteSnow = mode(0xfcfcfc, 0x070a0d)
    static let streamOverlayLight = mode(0xfcfcfc, lightAlpha: 0.9, 0x070a0d, darkAlpha: 0.9)
    static let streamWhite = mode(0xffffff, 0x101418)
    static let streamBlueAlice = mode(0xe9f2ff, 0x00193d)
    static let streamAccentBlue = mode(0x005fff, 0x005fff)
    static let streamAccentRed = mode(0xff3742, 0xff3742)
    static let streamAccentGreen = mode(0x00e2a1, 0x00e2a1)
    static let streamGrayDisabledText = mode(0x72767e, 0x72767e)
    static let streamInnerBorder = mode(0xdbdde1, 0x272a30)
    static let streamHighlight = mode(0xfbf4dd, 0x333024)
    static let streamDisabled = mode(0xb4b7bb, 0x4c525c)
    static let streamDarkBackground = mode(0x101213, 0x101213)
    static let streamPulsingColor = mode(0x005fff, 0x005fff)
    static let streamCallControlsBackground = mode(0xffffff, 0x1c1e22)
    static let streamWaitingRoomBackground = mode(0xffffff, 0x2c2c2e)
    static let streamWaitingRoomSecondaryBackground = mode(0xf2f2f2, 0x1c1c1e)
    static let streamParticipantBackground = mode(0x19232d, 0x19232d)

    // Currently we are not using the correct shadow color from figma's color palette. This is to avoid
    // an issue with snapshots inconsistency between Intel vs M1. We can't use shadows with transparency.
    // So we apply a light gray color to fake the transparency.
    static let streamModalShadow = mode(0xd6d6d6, lightAlpha: 1, 0, darkAlpha: 1)

    static let streamWhiteStatic = mode(0xffffff, 0xffffff)

    static let streamBGGradientFrom = mode(0xf7f7f7, 0x101214)
    static let streamBGGradientTo = mode(0xfcfcfc, 0x070a0d)
    static let streamOverlay = mode(0x000000, lightAlpha: 0.2, 0x000000, darkAlpha: 0.4)
    static let streamOverlayDark = mode(0x000000, lightAlpha: 0.6, 0xffffff, darkAlpha: 0.8)
    static let streamOverlayDarkStatic = mode(0x000000, lightAlpha: 0.6, 0x000000, darkAlpha: 0.6)

    static func mode(_ light: Int, lightAlpha: CGFloat = 1.0, _ dark: Int, darkAlpha: CGFloat = 1.0) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(rgb: dark).withAlphaComponent(darkAlpha)
                : UIColor(rgb: light).withAlphaComponent(lightAlpha)
        }
    }
}
