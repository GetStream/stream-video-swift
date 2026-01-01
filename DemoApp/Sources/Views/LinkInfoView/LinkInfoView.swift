//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct LinkInfoView: View {

    @Injected(\.appearance) var appearance

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(appearance.colors.primaryButtonBackground)
                    .frame(width: 36, height: 36)

                Image("logo")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22)
                    .foregroundColor(.white)
            }

            Text("Send the URL below to someone to have them join this call:")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
                .foregroundColor(appearance.colors.text)

            Spacer()
        }
    }
}
