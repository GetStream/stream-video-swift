//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct ReactionIcon: View {

    @Injected(\.layout) private var layout

    var iconName: String
    var width: CGFloat?

    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width ?? layout.buttonVisualHeightMd)
            .symbolRenderingMode(.multicolor)
            .foregroundColor(Color(red: 1, green: 0.8, blue: 0.2))
    }
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
