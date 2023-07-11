//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import CryptoKit
import Foundation
import StreamVideo

extension Data {
    func urlSafeBase64EncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

struct Header: Encodable {
    let alg = "HS256"
    let typ = "JWT"
}

struct JWTPayload: Encodable {
    let user_id: String
    let exp: Int
}

class TokenGenerator {
    
    static let shared = TokenGenerator()
    
    func fetchToken(for userId: String, expiration tokenDurationInMinutes: Double = 0) -> UserToken? {
        let secret = ProcessInfo.processInfo.environment["STREAM_VIDEO_SECRET"]
        guard let secret = secret else { return nil }
        
        let privateKey = SymmetricKey(data: secret.data(using: .utf8)!)
        
        guard let headerJSONData = try? JSONEncoder().encode(Header()) else { return nil }
        let headerBase64String = headerJSONData.urlSafeBase64EncodedString()
        
        let timeInterval = TimeInterval(tokenDurationInMinutes * 60)
        let expirationDate = Date().addingTimeInterval(timeInterval)
        let expiration = Int(expirationDate.timeIntervalSince1970)
        
        guard let payloadJSONData = try? JSONEncoder().encode(JWTPayload(user_id: userId, exp: expiration)) else { return nil }
        let payloadBase64String = payloadJSONData.urlSafeBase64EncodedString()
        
        let toSign = (headerBase64String + "." + payloadBase64String).data(using: .utf8)!
        let signature = HMAC<SHA256>.authenticationCode(for: toSign, using: privateKey)
        let signatureBase64String = Data(signature).urlSafeBase64EncodedString()
        
        let token = [headerBase64String, payloadBase64String, signatureBase64String].joined(separator: ".")
        return UserToken(rawValue: token)
    }
}
