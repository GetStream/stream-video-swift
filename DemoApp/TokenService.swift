//
//  TokenService.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 2.3.23.
//

import Foundation
import StreamVideo

class TokenService {

    enum TokenServiceError: Error, CustomStringConvertible {
        case unableToCreateURL
        case unableToCreateURLFromComponents

        var description: String {
            switch self {
            case .unableToCreateURL:
                return "We were unable to construct the URL to fetch a new auth token."
            case .unableToCreateURLFromComponents:
                return "We were unable to construct the URL (from URLComponents) to fetch a new auth token."
            }
        }
    }

    private let httpClient: HTTPClient = URLSessionClient()
    
    static let shared = TokenService()
    
    private init() {}

    private lazy var url: URL = URL(string: "https://stream-calls-dogfood.vercel.app")!
        .appendingPathComponent("api")
        .appendingPathComponent("auth")
        .appendingPathComponent("create-token")

    private func url(with queryParameters: [String: String]) throws -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TokenServiceError.unableToCreateURL
        }

        components.queryItems = queryParameters
            .map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let result = components.url else {
            throw TokenServiceError.unableToCreateURLFromComponents
        }

        return result
    }

    func fetchToken(for userId: String, callIds: [String] = []) async throws -> UserToken {
        var parameters: [String: String] = [
            "user_id": userId,
            "api_key": Config.apiKey
        ]

        if !callIds.isEmpty {
            parameters["call_cids"] = callIds.joined(separator: ",")
        }

        let url = try url(with: parameters)
        let tokenResponse: TokenResponse = try await httpClient.execute(url: url)
        let token = UserToken(rawValue: tokenResponse.token)
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
    static let baseURL = URL(string: "https://staging.getstream.io/")!
    static let appURLScheme = "streamvideo"
}
