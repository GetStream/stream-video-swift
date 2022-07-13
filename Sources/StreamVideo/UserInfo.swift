//
//  UserInfo.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 11.7.22.
//

import Foundation

public struct UserInfo {
    public let id: String
    public let name: String?
    public let imageURL: URL?
    public let extraData: [String: RawJSON]

    public init(
        id: String,
        name: String? = nil,
        imageURL: URL? = nil,
        extraData: [String: RawJSON] = [:]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.extraData = extraData
    }
}
