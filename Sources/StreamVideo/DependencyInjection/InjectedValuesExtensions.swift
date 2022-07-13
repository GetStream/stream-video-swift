//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension InjectedValues {
    /// Provides access to the `StreamVideo` instance in the views and view models.
    public var streamVideo: StreamVideo {
        get {
            guard let injected = Self[StreamVideoProviderKey.self] else {
                fatalError("Video client was not setup")
            }
            return injected
        }
        set {
            Self[StreamVideoProviderKey.self] = newValue
        }
    }
    
    var callCoordinatorService: Stream_Video_CallCoordinatorService {
        get {
            streamVideo.callCoordinatorService
        }
        set {
            streamVideo.callCoordinatorService = newValue
        }
    }
}
