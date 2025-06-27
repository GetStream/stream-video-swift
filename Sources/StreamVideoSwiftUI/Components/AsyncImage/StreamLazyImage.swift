//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct StreamLazyImage<Placeholder: View>: View {

    public var imageURL: URL?
    public var contentMode: ContentMode
    public var placeholder: () -> Placeholder

    public init(
        imageURL: URL?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.imageURL = imageURL
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    public init(
        imageURL: URL?,
        contentMode: ContentMode = .fill
    ) where Placeholder == EmptyView {
        self.init(
            imageURL: imageURL,
            contentMode: contentMode,
            placeholder: { EmptyView() }
        )
    }

    public var body: some View {
        if let imageURL {
            StreamAsyncImage(
                url: imageURL,
                content: { image in applyResizingMode { image } },
                placeholder: placeholder
            )
        } else {
            placeholder()
        }
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func applyResizingMode(
        @ViewBuilder content: () -> Image
    ) -> some View {
        switch contentMode {
        case .fit:
            content()
                .resizable()
                .scaledToFit()
        case .fill:
            content()
                .resizable()
                .scaledToFill()
        }
    }
}
