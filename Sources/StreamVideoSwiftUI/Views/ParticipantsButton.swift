//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct ParticipantsButton: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    
    private let cornerRadius: CGFloat = 24
    
    var title: String
    var primaryStyle: Bool = true
    var onTapped: () -> Void
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            Text(title)
                .font(fonts.headline)
                .bold()
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundColor(
                    primaryStyle ? colors.textInverted : colors.secondaryButton
                )
                .background(primaryStyle ? colors.tintColor : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(primaryStyle ? colors.tintColor : colors.secondaryButton, lineWidth: 1)
                )
                .cornerRadius(cornerRadius)
        }
    }
}
