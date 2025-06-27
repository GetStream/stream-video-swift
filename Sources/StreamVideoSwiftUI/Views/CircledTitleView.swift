//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CircledTitleView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    
    var title: String
    var size: CGFloat = .expandedAvatarSize
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(colors.tintColor)

            Text(title)
                .foregroundColor(.white)
                .font(fonts.title)
                .minimumScaleFactor(0.4)
                .padding()
        }
        .frame(maxWidth: size, maxHeight: size)
        .modifier(ShadowModifier())
        .debugViewRendering()
    }
}
