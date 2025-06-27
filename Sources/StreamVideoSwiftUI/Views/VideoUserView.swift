//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct VideoUserView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    
    private let avatarSize: CGFloat = 56

    var viewFactory: Factory
    var user: User
    var isSelected: Bool

    init(
        viewFactory: Factory,
        user: User,
        isSelected: Bool
    ) {
        self.viewFactory = viewFactory
        self.user = user
        self.isSelected = isSelected
    }

    var body: some View {
        HStack {
            viewFactory.makeUserAvatar(user, with: .init(size: avatarSize))

            Text(user.name)
                .lineLimit(1)
                .font(fonts.bodyBold)

            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .renderingMode(.template)
                    .foregroundColor(colors.tintColor)
            }
        }
        .debugViewRendering()
    }
}
