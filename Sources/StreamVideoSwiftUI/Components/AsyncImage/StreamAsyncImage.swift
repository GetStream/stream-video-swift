//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

struct StreamAsyncImage<Content: View>: View {

    @Injected(\.imagesRepository) private var imagesRepository

    var url: URL?
    var scale: CGFloat
    var conditionalContent: ((Image?) -> Content)

    @State var taskState: ImagesRepository.TaskState = .idle

    init<I, P>(
        url: URL?,
        scale: CGFloat = 1,
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I: View, P: View {
        self.url = url
        self.scale = scale
        conditionalContent = { image in
            if let image = image {
                return ViewBuilder.buildEither(first: content(image))
            } else {
                return ViewBuilder.buildEither(second: placeholder())
            }
        }

        if let url {
            imagesRepository.image(for: url)
        }
    }

    var body: some View {
        if let url {
            Group {
                switch taskState {
                case .idle:
                    conditionalContent(nil)
                case .loading:
                    if #available(iOS 14.0, *) {
                        ProgressView()
                    }
                case let .loaded(data):
                    if let image = UIImage(data: data) {
                        conditionalContent(Image(uiImage: image))
                    } else {
                        conditionalContent(nil)
                    }
                case .failed:
                    conditionalContent(nil)
                }
            }
            .onReceive(imagesRepository.$storage.compactMap { $0[url] }.receive(on: DispatchQueue.main)) { taskState = $0 }
        }
    }
}
