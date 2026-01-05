//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct CallButtonView: View {
    @Injected(\.appearance) var appearance

    var title: String
    var maxWidth: CGFloat?
    var isDisabled: Bool

    var body: some View {
        Text(title)
            .bold()
            .foregroundColor(.white)
            .padding(.all, 12)
            .frame(maxWidth: maxWidth ?? .infinity)
            .background(isDisabled ? appearance.colors.lightGray : appearance.colors.primaryButtonBackground)
            .cornerRadius(8)
    }
}
