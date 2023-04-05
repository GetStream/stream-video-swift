//
//  TokenService.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 2.3.23.
//

import Foundation
import StreamVideo

class TokenService {
    
    lazy var tokenURL = "\(baseURL)/api/auth/create-token?user_id="
    let baseURL = "https://stream-calls-dogfood.vercel.app"
    
    private let httpClient: HTTPClient = URLSessionClient()
    
    static let shared = TokenService()
    
    private init() {}
    
    func fetchToken(for userId: String) async throws -> UserToken {
        let urlString = tokenURL + userId + "&api_key=\(Config.apiKey)"
        guard let url = URL(string: urlString) else {
            throw ClientError.Unexpected()
        }
        let tokenResponse: TokenResponse = try await httpClient.execute(url: url)
        let token = try UserToken(rawValue: tokenResponse.token)
        return token
    }
    
}

struct TokenResponse: Codable {
    let userId: String
    let token: String
}

struct Config {
    static let apiKey = apiKeyStaging
    static let apiKeyStaging = "hd8szvscpxvd"
    static let apiKeyLocal = "892s22ypvt6m"
}
