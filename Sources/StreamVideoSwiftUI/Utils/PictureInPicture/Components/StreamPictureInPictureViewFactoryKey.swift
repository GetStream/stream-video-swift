//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo

enum StreamPictureInPictureViewFactoryKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: any ViewFactory = DefaultViewFactory.shared
}

extension InjectedValues {
    public var pictureInPictureViewFactory: any ViewFactory {
        get { Self[StreamPictureInPictureViewFactoryKey.self] }
        set { Self[StreamPictureInPictureViewFactoryKey.self] = newValue }
    }
}
