//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore

/// An API error returned by Stream.
public typealias APIError = StreamCore.APIError

extension StreamCore.APIError: JSONEncodable {
    func encodeToJSON() -> Any {
        guard let data = try? CodableHelper.jsonEncoder.encode(self) else {
            fatalError("Could not encode to json: \(self)")
        }
        return data.encodeToJSON()
    }
}
