//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

public enum BackgroundType {
    case circle
    case rectangle
    case none
}

extension Image {
    
    public func applyCallButtonStyle(
        color: Color,
        glyphColor: Color = Color(
            InjectedValues[\.videoAppearance].colors.controlAcceptCallButtonText
        ),
        backgroundType: BackgroundType = .circle,
        size: CGFloat = 64
    ) -> some View {
        resizable()
            .foregroundColor(color)
            .aspectRatio(contentMode: .fit)
            .frame(width: size)
            .frame(maxHeight: size)
            .background(background(for: backgroundType, glyphColor: glyphColor))
            .modifier(ShadowModifier())
    }
    
    @ViewBuilder
    func background(for type: BackgroundType, glyphColor: Color) -> some View {
        if type == .none {
            EmptyView()
        } else if type == .circle {
            glyphColor.mask(Circle())
        } else {
            glyphColor.mask(
                Rectangle().padding(
                    InjectedValues[\.videoAppearance].tokens.layout.spacingSm
                )
            )
        }
    }
}

extension View {
    
    public func adjustVideoFrame(to width: CGFloat, ratio: CGFloat = 0.5) -> some View {
        aspectRatio(ratio, contentMode: .fill)
            .frame(width: width)
            .clipped()
    }
}

/// Modifier for adding shadow and corner radius to a view.
struct ShadowViewModifier: ViewModifier {
    
    var cornerRadius: CGFloat = InjectedValues[\.videoAppearance].tokens.layout.radiusXl
    var borderColor: Color = Color(InjectedValues[\.videoAppearance].tokens.colors.borderCoreDefault)

    func body(content: Content) -> some View {
        content
            .background(Color(colors.backgroundCoreElevation1))
            .cornerRadius(cornerRadius)
            .modifier(ShadowModifier())
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        borderColor,
                        lineWidth: 0.5
                    )
            )
    }
}

/// Modifier for adding shadow to a view.
struct ShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let primary = colorScheme == .dark ? layout.darkElevation3 : layout.lightElevation3
        let contact = colorScheme == .dark ? layout.darkElevation1 : layout.lightElevation1
        content
            .shadow(color: Color(primary.color), radius: primary.blur, x: primary.x, y: primary.y)
            .shadow(color: Color(contact.color), radius: contact.blur, x: contact.x, y: contact.y)
    }
}
