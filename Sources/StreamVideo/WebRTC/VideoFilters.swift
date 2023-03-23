//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

public final class VideoFilter: @unchecked Sendable {
    /// The ID of the video filter.
    public let id: String

    /// The name of the video filter.
    public let name: String

    /// Filter closure that takes a CIImage as input and returns a filtered CIImage as output.
    public var filter: (CIImage) async -> CIImage

    /// Initializes a new VideoFilter instance with the provided parameters.
    /// - Parameters:
    ///   - id: The ID of the video filter.
    ///   - name: The name of the video filter.
    ///   - filter: The filter closure that takes a CIImage as input and returns a filtered CIImage as output.
    public init(id: String, name: String, filter: @escaping (CIImage) async -> CIImage) {
        self.id = id
        self.name = name
        self.filter = filter
    }
}
