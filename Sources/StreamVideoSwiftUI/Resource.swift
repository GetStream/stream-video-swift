//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Resource {
    public var bundle: Bundle
    public var name: String
    public var `extension`: String?

    var url: URL? { bundle.url(forResource: name, withExtension: self.extension) }
}
