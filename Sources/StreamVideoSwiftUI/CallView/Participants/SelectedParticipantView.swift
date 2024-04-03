//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct SelectedParticipantView: View {
    
    @Injected(\.fonts) var fonts
    
    private let avatarSize: CGFloat = 50
    
    var user: User
    var onUserTapped: (User) -> Void
    
    var body: some View {
        VStack {
            UserAvatar(imageURL: user.imageURL, size: avatarSize)

            Text(user.name)
                .lineLimit(1)
                .font(fonts.footnote)
        }
        .overlay(
            TopRightView {
                Button(action: {
                    withAnimation {
                        onUserTapped(user)
                    }
                }, label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                        
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.black.opacity(0.8))
                    }
                    .padding(.all, 4)
                })
            }
            .offset(x: 6, y: -4)
        )
        .frame(width: avatarSize)
    }
}
