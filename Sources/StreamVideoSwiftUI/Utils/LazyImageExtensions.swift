//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
extension LazyImage {

    init(imageURL: URL?) where Content == NukeImage {
        #if COCOAPODS
        self.init(source: imageURL)
        #else
        self.init(url: imageURL, resizingMode: .aspectFill)
        #endif
    }

    init(imageURL: URL?, @ViewBuilder content: @escaping (LazyImageState) -> Content) {
        #if COCOAPODS
        self.init(source: imageURL, content: content)
        #else
        self.init(url: imageURL, content: content)
        #endif
        return
    }
}

@available(iOS 14.0, *)
public struct StreamLazyImage<Failback: View>: View {
    
    public typealias FailbackProvider = () -> Failback

    var imageURL: URL?
    var failback: FailbackProvider?

    @State private var failedToLoadContent = false

    public init(imageURL: URL?, failback: FailbackProvider? = nil) {
        self.imageURL = imageURL
        self.failback = failback
    }
    
    public var body: some View {
        if failedToLoadContent, let failback {
            failback()
        } else {
#if STREAM_SNAPSHOT_TESTS
            if let imageURL = imageURL,
               imageURL.isFileURL,
               let image = UIImage(contentsOfFile: imageURL.path)  {
                NukeImage(image)
                    .aspectRatio(contentMode: .fill)
            } else {
                LazyImage(imageURL: imageURL)
                    .onFailure { _ in self.failedToLoadContent = true }
            }
#else
            LazyImage(imageURL: imageURL)
                .onFailure { _ in self.failedToLoadContent = true }
#endif
        }
    }
}

@available(iOS 14.0, *)
extension StreamLazyImage where Failback == EmptyView {

    public init(imageURL: URL?) {
        self.init(imageURL: imageURL, failback: { EmptyView() })
    }
}
