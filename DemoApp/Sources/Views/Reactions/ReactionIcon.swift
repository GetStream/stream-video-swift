//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ReactionIcon: View {

    @Injected(\.videoAppearance) private var videoAppearance

    var iconName: String
    var width: CGFloat?
    var foregroundColor: Color?

    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width ?? tokens.layout.buttonVisualHeightMd)
            .foregroundColor(foregroundColor ?? Color(tokens.colors.accentWarning))
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct ReactionIcon_Previews: PreviewProvider {
    static var previews: some View {
        let sizes: [CGFloat] = [20, 40, 60]
        let colors: [Color] = [.yellow, .red, .blue]
        let reactions: [Reaction] = [.like, .raiseHand]

        ForEach(colors, id: \.self) { color in
            ForEach(sizes, id: \.self) { size in
                HStack {
                    ForEach(reactions) { reaction in
                        ReactionIcon(
                            iconName: reaction.iconName,
                            width: size,
                            foregroundColor: color
                        )
                    }
                }
                .previewLayout(.sizeThatFits)
            }
        }
    }
}
