//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a control badge displaying a value.
public struct ControlBadgeView: View {
    @Injected(\.videoAppearance) private var videoAppearance

    enum Content {
        case text(String, foreground: Color, background: Color)
        case image(Image, foreground: Color, background: Color)
    }

    /// The value to be displayed within the badge.
    var content: Content

    /// Initializes a control badge view with the specified value.
    /// - Parameter value: The value to display within the badge.
    public init(
        _ value: String,
        foreground: Color = InjectedValues[\.colors].textInverted,
        background: Color = InjectedValues[\.colors].onlineIndicatorColor
    ) {
        content = .text(
            value,
            foreground: foreground,
            background: background
        )
    }

    public init(
        _ image: Image,
        foreground: Color = InjectedValues[\.colors].textInverted,
        background: Color = InjectedValues[\.colors].onlineIndicatorColor
    ) {
        content = .image(
            image,
            foreground: foreground,
            background: background
        )
    }

    public var body: some View {
        TopRightView {
            contentView
                .frame(
                    width: videoAppearance.tokens.layout.iconSizeSm,
                    height: videoAppearance.tokens.layout.iconSizeSm
                )
                .padding(videoAppearance.tokens.layout.spacingXxxs)
                .font(videoAppearance.tokens.fonts.caption1)
                .foregroundColor(foregroundColor)
                .background(Circle().fill(backgroundColor))
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch content {
        case let .text(string, _, _):
            Text(string)
                .minimumScaleFactor(0.3)
        case let .image(image, _, _):
            image
        }
    }

    private var foregroundColor: Color {
        switch content {
        case let .text(_, foreground, _):
            return foreground
        case let .image(_, foreground, _):
            return foreground
        }
    }

    private var backgroundColor: Color {
        switch content {
        case let .text(_, _, background):
            return background
        case let .image(_, _, background):
            return background
        }
    }
}

extension View {

    @ViewBuilder
    public func badge(
        _ value: String,
        foreground: Color = InjectedValues[\.colors].textInverted,
        background: Color = InjectedValues[\.colors].onlineIndicatorColor
    ) -> some View {
        overlay(
            ControlBadgeView(
                value,
                foreground: foreground,
                background: background
            )
        )
    }

    @ViewBuilder
    public func badge(
        _ value: Image,
        foreground: Color = InjectedValues[\.colors].textInverted,
        background: Color = InjectedValues[\.colors].onlineIndicatorColor
    ) -> some View {
        overlay(
            ControlBadgeView(
                value,
                foreground: foreground,
                background: background
            )
        )
    }
}
