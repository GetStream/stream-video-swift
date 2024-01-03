//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
public struct UserAvatar<Failback: View>: View {

    public typealias FailbackProvider = () -> Failback

    public var imageURL: URL?
    public var size: CGFloat
    public var failbackProvider: FailbackProvider?

    public init(imageURL: URL?, size: CGFloat, failbackProvider: FailbackProvider?) {
        self.imageURL = imageURL
        self.size = size
        self.failbackProvider = failbackProvider
    }
    
    public var body: some View {
        StreamLazyImage(imageURL: imageURL, failback: failbackProvider)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

@available(iOS 14.0, *)
extension UserAvatar where Failback == EmptyView {

    public init(imageURL: URL?, size: CGFloat) {
        self.init(imageURL: imageURL, size: size, failbackProvider: nil)
    }
}
