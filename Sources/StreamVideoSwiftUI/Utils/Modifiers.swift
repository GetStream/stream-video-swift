//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

enum BackgroundType {
    case circle
    case rectangle
    case none
}

extension Image {
    
    func applyCallButtonStyle(
        color: Color,
        backgroundType: BackgroundType = .circle,
        size: CGFloat = 64
    ) -> some View {
        resizable()
            .foregroundColor(color)
            .aspectRatio(contentMode: .fit)
            .frame(width: size)
            .frame(maxHeight: size)
            .background(background(for: backgroundType))
            .modifier(ShadowModifier())
    }
    
    @ViewBuilder
    func background(for type: BackgroundType) -> some View {
        if type == .none {
            EmptyView()
        } else if type == .circle {
            Color.white.mask(Circle())
        } else {
            Color.white.mask(Rectangle().padding(12))
        }
    }
}

extension Text {
    
    func applyCallingStyle() -> some View {
        font(InjectedValues[\.fonts].title2)
            .fontWeight(.semibold)
            .foregroundColor(InjectedValues[\.colors].lightGray)
    }
}

/// Modifier for adding shadow and corner radius to a view.
struct ShadowViewModifier: ViewModifier {
    
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .modifier(ShadowModifier())
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.gray,
                        lineWidth: 0.5
                    )
            )
    }
}

/// Modifier for adding shadow to a view.
struct ShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}
