//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct LoadingView: View {

    @Injected(\.videoAppearance) var videoAppearance

    init() {}

    var body: some View {
        ZStack {
            VStack(spacing: tokens.layout.spacingMd) {
                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: tokens.layout.spacingXxxs) {
                    Text("Loading...")
                        .font(tokens.fonts.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(tokens.colors.textSecondary))
                        .accessibility(identifier: "loadingView")
                }

                Spacer()
            }
        }
        .background(
            Color(tokens.colors.backgroundCoreApp)
                .edgesIgnoringSafeArea(.all)
        )
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
