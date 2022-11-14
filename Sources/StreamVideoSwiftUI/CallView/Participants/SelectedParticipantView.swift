//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

struct SelectedParticipantView: View {
    
    @Injected(\.fonts) var fonts
    
    private let avatarSize: CGFloat = 50
    
    var user: User
    var onUserTapped: (User) -> Void
    
    var body: some View {
        VStack {
            LazyImage(url: user.imageURL)
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
            
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
