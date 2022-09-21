//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

class MockTokenGenerator {
    
    static func generateToken(for userInfo: UserInfo, callId: String) -> String {
        let paramsSFU: [String: RawJSON] = [
            "app_id": .number(42), "call_id": .string(callId),
            "user": .dictionary(["id": .string(userInfo.id), "image_url": .string(userInfo.imageURL?.absoluteString ?? "")]),
            "grants": .dictionary([
                "can_join_call": .bool(true),
                "can_publish_video": .bool(true),
                "can_publish_audio": .bool(true),
                "can_screen_share": .bool(true),
                "can_mute_video": .bool(true),
                "can_mute_audio": .bool(true)
            ]),
            "iss": .string("dev-only.pubkey.ecdsa256"), "aud": .array([.string("localhost")])
        ]
        var paramsString = ""
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(paramsSFU) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                paramsString = Data(jsonString.utf8).base64EncodedString()
            }
        }
        let tokenSFU = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.\(paramsString).SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
            .replacingOccurrences(of: "=", with: "")
        return tokenSFU
    }
    
}
