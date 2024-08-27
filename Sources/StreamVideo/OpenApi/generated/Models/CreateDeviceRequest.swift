//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CreateDeviceRequest: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public enum PushProvider: String, Codable, CaseIterable {
        case apn
        case firebase
        case huawei
        case xiaomi
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public var id: String
    public var pushProvider: PushProvider
    public var pushProviderName: String? = nil
    public var voipToken: Bool? = nil

    public init(id: String, pushProvider: PushProvider, pushProviderName: String? = nil, voipToken: Bool? = nil) {
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
        self.voipToken = voipToken
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
        case voipToken = "voip_token"
    }
}
