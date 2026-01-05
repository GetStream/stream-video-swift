//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct StreamLazyImage<Placeholder: View>: View {

    public var imageURL: URL?
    public var contentMode: ContentMode
    public var placeholder: () -> Placeholder

    public init(
        imageURL: URL?,
        contentMode: ContentMode = .fill,
        placeholder: @escaping () -> Placeholder
    ) {
        self.imageURL = imageURL
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    public var body: some View {
        if let localImage = localImage {
            applyResizingMode { localImage }
        } else {
            StreamAsyncImage(
                url: imageURL,
                content: { image in applyResizingMode { image } },
                placeholder: placeholder
            )
        }
    }

    // MARK: - Private Helpers

    private var localImage: Image? {
        guard
            let imageURL = imageURL,
            let image = UIImage(contentsOfFile: imageURL.path)
        else {
            return nil
        }
        return Image(uiImage: image)
    }

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

extension StreamLazyImage where Placeholder == EmptyView {

    public init(
        imageURL: URL?,
        contentMode: ContentMode = .fill
    ) {
        self.init(
            imageURL: imageURL,
            contentMode: contentMode,
            placeholder: { EmptyView() }
        )
    }
}
