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

    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width ?? tokens.layout.buttonVisualHeightMd)
            .symbolRenderingMode(.multicolor)
            .foregroundColor(Color(red: 1, green: 0.8, blue: 0.2))
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct ReactionIcon_Previews: PreviewProvider {
    static var previews: some View {
        let reactions: [Reaction] = [.like, .dislike, .heart, .smile, .fireworks, .raiseHand]

        HStack {
            ForEach(reactions) { reaction in
                ReactionIcon(iconName: reaction.iconName)
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
