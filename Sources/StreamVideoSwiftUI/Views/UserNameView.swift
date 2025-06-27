//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct UserNameView: View {
    @Injected(\.fonts) private var fonts

    var name: String

    var body: some View {
        Text(name)
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .font(fonts.caption1)
            .minimumScaleFactor(0.7)
            .accessibility(identifier: "participantName")
            .debugViewRendering()
    }
}
