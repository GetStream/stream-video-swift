//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

internal class JSONEncodingHelper {

    internal class func encodingParameters<T: Encodable>(forEncodableObject encodableObj: T?) -> [String: Any]? {
        var params: [String: Any]?

        // Encode the Encodable object
        if let encodableObj = encodableObj {
            let encodeResult = CodableHelper.encode(encodableObj)
            do {
                let data = try encodeResult.get()
                params = JSONDataEncoding.encodingParameters(jsonData: data)
            } catch {
                print(error.localizedDescription)
            }
        }

        return params
    }

    internal class func encodingParameters(forEncodableObject encodableObj: Any?) -> [String: Any]? {
        var params: [String: Any]?

        if let encodableObj = encodableObj {
            do {
                let data = try JSONSerialization.data(withJSONObject: encodableObj, options: .prettyPrinted)
                params = JSONDataEncoding.encodingParameters(jsonData: data)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }

        return params
    }
}
