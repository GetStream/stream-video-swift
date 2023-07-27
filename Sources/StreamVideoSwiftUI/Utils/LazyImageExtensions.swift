//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Nuke
import NukeUI
import SwiftUI

@available(iOS 14.0, *)
extension LazyImage {

    public init(imageURL: URL?) where Content == NukeUI.Image {
        #if COCOAPODS
        self.init(source: imageURL)
        #else
        self.init(url: imageURL, resizingMode: .aspectFill)
        #endif
    }

    public init(imageURL: URL?, @ViewBuilder content: @escaping (LazyImageState) -> Content) {
        #if COCOAPODS
        self.init(source: imageURL, content: content)
        #else
        self.init(url: imageURL, content: content)
        #endif
        return
    }
}

@available(iOS 14.0, *)
struct StreamLazyImage: View {
    
    var imageURL: URL?
    
    public init(imageURL: URL?) {
        self.imageURL = imageURL
    }
    
    public var body: some View {
        #if STREAM_SNAPSHOT_TESTS
        if let imageURL = imageURL,
           imageURL.isFileURL,
           let image = UIImage(contentsOfFile: imageURL.path)  {
            Image(image)
                .aspectRatio(contentMode: .fill)
        } else {
            LazyImage(imageURL: imageURL)
        }
        #else
        LazyImage(imageURL: imageURL)
        #endif
    }
}
