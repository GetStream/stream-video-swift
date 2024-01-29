import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    container {
        struct CustomView: View {
            var body: some View {
                YourView()
                    .background(CallBackground(imageURL: imageURL))
            }
        }
    }
}

