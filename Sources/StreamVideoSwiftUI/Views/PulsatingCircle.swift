//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct PulsatingCircle: View {
    
    @Injected(\.colors) var colors
    var scaleEffect: CGFloat
    var opacity: CGFloat
    var isCalling: Bool
    var size: CGFloat = .expandedAvatarSize
    var animation: Animation = .easeOut(duration: 1).repeatForever(autoreverses: true)
    
    var body: some View {
        Circle()
            .fill(colors.callPulsingColor)
            .frame(width: size, height: size)
            .opacity(opacity)
            .scaleEffect(scaleEffect)
            .animation(animation, value: isCalling)
    }
}
