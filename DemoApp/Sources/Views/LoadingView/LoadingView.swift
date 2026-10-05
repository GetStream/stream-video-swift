//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct LoadingView: View {

    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    init() {}

    var body: some View {
        ZStack {
            VStack(spacing: layout.spacingMd) {
                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: layout.spacingXxxs) {
                    Text("Loading...")
                        .font(fonts.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(colors.textSecondary))
                        .accessibility(identifier: "loadingView")
                }

                Spacer()
            }
        }
        .background(
            Color(colors.backgroundCoreApp)
                .edgesIgnoringSafeArea(.all)
        )
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
