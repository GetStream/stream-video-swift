//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct LinkInfoView: View {

    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    var body: some View {
        HStack(spacing: layout.spacingMd) {
            ZStack {
                Circle()
                    .fill(Color(colors.buttonPrimaryBackground))
                    .frame(width: 36, height: 36)

                Image("logo")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22)
                    .foregroundColor(Color(colors.buttonPrimaryTextOnAccent))
            }

            Text("Send the URL below to someone to have them join this call:")
                .font(fonts.headline)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
                .foregroundColor(Color(colors.textPrimary))

            Spacer()
        }
    }
}
