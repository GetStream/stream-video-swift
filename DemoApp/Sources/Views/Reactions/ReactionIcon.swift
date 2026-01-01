//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct ReactionIcon: View {

    var iconName: String
    var width: CGFloat = 40
    var foregroundColor: Color = .yellow

    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width)
            .foregroundColor(foregroundColor)
    }
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
