//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    
    var retries = 0
    
    func fetchToken(
        for userId: String,
        expiration tokenDurationInSeconds: Int = 0
    ) -> UserToken? {
        #if STREAM_E2E_TESTS
        if ProcessInfo.processInfo.arguments.contains("INVALIDATE_JWT") {
            if retries == 0 {
                retries += 1
                /// - Important: The token has been created with Demo Environment apiKey. If we
                /// ever change the environment on which we run UITests against, then this token
                /// will need to be recreated.
                return UserToken(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFydGluIiwiZXhwIjoxNjA3OTIxMTM3fQ.eKokB6oC-ZesrD28OPh-96tp_ykulJYiFZY76lG-eRA")
            }
        }
        
        if ProcessInfo.processInfo.arguments.contains("BREAK_JWT") {
            return UserToken(rawValue: "")
        }
        #endif
        
        let secret = ProcessInfo.processInfo.environment["STREAM_VIDEO_SECRET"]!
        let privateKey = SymmetricKey(data: secret.data(using: .utf8)!)
        
        guard let headerJSONData = try? JSONEncoder().encode(Header()) else { return nil }
        let headerBase64String = headerJSONData.urlSafeBase64EncodedString()
        
        let timeInterval = TimeInterval(tokenDurationInSeconds)
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
