//
// ICEServer.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif





public struct ICEServer: Codable, JSONEncodable, Hashable {

    public var password: String
    public var urls: [String]
    public var username: String

    public init(password: String, urls: [String], username: String) {
        self.password = password
        self.urls = urls
        self.username = username
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case password
        case urls
        case username
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(password, forKey: .password)
        try container.encode(urls, forKey: .urls)
        try container.encode(username, forKey: .username)
    }
}

