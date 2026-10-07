//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct Spacing: View {

    var size = 1

    var body: some View {
        ForEach(0..<size, id: \.self) { _ in
            Spacer()
        }
    }
}

public struct CallIconView: View {

    @Injected(\.layout) var layout

    var icon: Image
    var size: CGFloat = 64
    var iconStyle: CallIconStyle = .primary

    public init(
        icon: Image,
        size: CGFloat = 64,
        iconStyle: CallIconStyle = .primary
    ) {
        self.icon = icon
        self.size = size
        self.iconStyle = iconStyle
    }

    public var body: some View {
        ZStack {
            Circle().fill(
                iconStyle.backgroundColor.opacity(iconStyle.opacity)
            )
            icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    maxWidth: layout.iconSizeMd,
                    maxHeight: layout.iconSizeMd
                )
                .foregroundColor(iconStyle.foregroundColor)
        }
        .frame(width: size, height: size)
        .modifier(ShadowModifier())
    }
}

public struct CallIconStyle {
    public let backgroundColor: Color
    public let foregroundColor: Color
    public let opacity: CGFloat
}

extension CallIconStyle {

    public nonisolated(unsafe) static let primary = CallIconStyle(
        backgroundColor: Color(
            InjectedValues[\.colors].buttonSecondaryBackground
        ),
        foregroundColor: Color(
            InjectedValues[\.colors].buttonSecondaryText
        ),
        opacity: 1
    )

    public nonisolated(unsafe) static let secondary = CallIconStyle(
        backgroundColor: Color(
            InjectedValues[\.colors].buttonSecondaryBackground
        ),
        foregroundColor: Color(
            InjectedValues[\.colors].buttonSecondaryText
        ),
        opacity: 1
    )

    public nonisolated(unsafe) static let secondaryActive = CallIconStyle(
        backgroundColor: Color(
            InjectedValues[\.colors].accentPrimary
        ),
        foregroundColor: Color(
            InjectedValues[\.colors].textOnAccent
        ),
        opacity: 1
    )

    public nonisolated(unsafe) static let transparent = CallIconStyle(
        backgroundColor: Color(
            InjectedValues[\.colors].buttonSecondaryBackground
        ),
        foregroundColor: Color(
            InjectedValues[\.colors].buttonSecondaryText
        ),
        opacity: 1
    )

    public nonisolated(unsafe) static let disabled = CallIconStyle(
        backgroundColor: Color(
            InjectedValues[\.colors].accentError
        ),
        foregroundColor: Color(
            InjectedValues[\.colors].textOnAccent
        ),
        opacity: 1
    )

    public nonisolated(unsafe) static let destructive = CallIconStyle(
        backgroundColor: Color(
            InjectedValues[\.colors].controlDeclineCallButtonBackground
        ),
        foregroundColor: Color(
            InjectedValues[\.colors].controlDeclineCallButtonText
        ),
        opacity: 1
    )
}

/// View used for the online indicator.
public struct OnlineIndicatorView: View {
    @Injected(\.colors) var colors

    var indicatorSize: CGFloat

    public var body: some View {
        ZStack {
            Circle()
                .fill(Color(colors.backgroundCoreApp))
                .frame(width: indicatorSize, height: indicatorSize)

            Circle()
                .fill(Color(colors.accentSuccess))
                .frame(width: innerCircleSize, height: innerCircleSize)
        }
    }

    private var innerCircleSize: CGFloat {
        2 * indicatorSize / 3
    }
}
