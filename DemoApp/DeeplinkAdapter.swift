//
//  DeeplinkAdapter.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/5/23.
//

import Foundation
import StreamVideo

struct DeeplinkInfo: Equatable {
    var callId: String
    var callType: String

    static let empty = DeeplinkInfo(callId: "", callType: "")
}

struct DeeplinkAdapter {
    var baseURL: URL

    func canHandle(url: URL) -> Bool {
        url.absoluteString.contains(baseURL.absoluteString)
    }

    func handle(url: URL) -> (deeplinkInfo: DeeplinkInfo, user: User)? {
        guard canHandle(url: url) else {
            return nil
        }

        let callId = url.lastPathComponent
        let callType = url.queryParameters["type"] ?? "default"

        guard
            let userId = url.queryParameters["user_id"],
            let user = User.builtInUsers.filter({ $0.id == userId }).first
        else {
            return nil
        }

        return (DeeplinkInfo(callId: callId, callType: callType), user)
    }
}
