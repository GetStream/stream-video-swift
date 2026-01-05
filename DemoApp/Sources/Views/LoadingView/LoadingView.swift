//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct LoadingView: View {

    init() {}

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("Loading...")
                        .applyCallingStyle()
                        .accessibility(identifier: "loadingView")
                }

                Spacer()
            }
        }
        .background(
            FallbackBackground()
        )
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}

// MARK: - Helpers

extension Text {
    func applyCallingStyle() -> some View {
        font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.init(.lightGray))
    }
}

struct FallbackBackground: View {
    var body: some View {
        DefaultBackgroundGradient()
            .aspectRatio(contentMode: .fill)
            .edgesIgnoringSafeArea(.all)
    }
}

struct DefaultBackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 60 / 255, green: 64 / 255, blue: 72 / 255),
                Color(red: 30 / 255, green: 33 / 255, blue: 36 / 255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
