//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct UsersHeaderView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    
    var title = L10n.Call.Participants.onPlatform
    
    var body: some View {
        HStack {
            Text(title)
                .padding(.horizontal)
                .padding(.vertical, 2)
                .font(fonts.body)
                .foregroundColor(Color(colors.textLowEmphasis))
            
            Spacer()
        }
        .background(Color(colors.background1))
    }
}
