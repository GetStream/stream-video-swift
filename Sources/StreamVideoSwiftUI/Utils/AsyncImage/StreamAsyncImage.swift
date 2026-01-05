//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

struct StreamAsyncImage<Content: View>: View {

    var url: URL?
    var scale: CGFloat
    var conditionalContent: ((Image?) -> Content)

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
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            AsyncImage(
                url: url,
                scale: scale,
                content: { conditionalContent($0) },
                placeholder: { conditionalContent(nil) }
            )
        } else {
            LegacyAsyncImage(
                url: url,
                scale: scale,
                content: { conditionalContent($0) },
                placeholder: { conditionalContent(nil) }
            )
        }
    }
}
