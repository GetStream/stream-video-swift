//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import NukeUI

@available(iOS 14.0, *)
public struct UserAvatar: View {
    
    public var imageURL: URL?
    public var size: CGFloat
    
    public init(imageURL: URL?, size: CGFloat) {
        self.imageURL = imageURL
        self.size = size
    }
    
    public var body: some View {
        StreamLazyImage(imageURL: imageURL)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}
