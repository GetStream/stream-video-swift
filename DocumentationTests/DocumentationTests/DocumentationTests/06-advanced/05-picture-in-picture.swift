//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        final class MyViewModel {
            @Injected(\.pictureInPictureAdapter) var pictureInPictureAdapter

            // A property holding the active call
            var call: Call? {
                didSet {
                    pictureInPictureAdapter.call = call
                }
            }
        }
    }

    container {
        struct CallView<Factory: ViewFactory>: View {
            @ObservedObject var viewModel: CallViewModel

            public var body: some View {
                YourHostView()
                    .enablePictureInPicture(viewModel.isPictureInPictureEnabled)
            }
        }
    }
}
