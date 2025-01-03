//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct UserAvatar<Failback: View>: View {

    public typealias FailbackProvider = () -> _ConditionalContent<Failback, EmptyView>

    public var imageURL: URL?
    public var size: CGFloat
    public var failbackProvider: FailbackProvider

    public init(imageURL: URL?, size: CGFloat, failbackProvider: (() -> Failback)?) {
        self.imageURL = imageURL
        self.size = size
        self.failbackProvider = {
            if let failbackProvider {
                return ViewBuilder.buildEither(first: failbackProvider())
            } else {
                return ViewBuilder.buildEither(second: EmptyView())
            }
        }
    }
    
    public var body: some View {
        StreamLazyImage(imageURL: imageURL, placeholder: failbackProvider)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

extension UserAvatar where Failback == EmptyView {

    public init(imageURL: URL?, size: CGFloat) {
        self.init(imageURL: imageURL, size: size, failbackProvider: nil)
    }
}
