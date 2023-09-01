//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension URL {

    var queryParameters: [String: String] {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }

    func addQueryParameter(_ key: String, value: String?) -> URL {
        if #available(iOS 16.0, *) {
            return appending(queryItems: [.init(name: key, value: value)])
        } else {
            guard
                var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
            else {
                return self
            }

            var queryItems: [URLQueryItem] = components.queryItems ?? []
            queryItems.append(.init(name: key, value: value))
            components.queryItems = queryItems

            return components.url ?? self
        }
    }

    func appending(_ queryItem: URLQueryItem) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + [queryItem]

        return components.url ?? self
    }
}
