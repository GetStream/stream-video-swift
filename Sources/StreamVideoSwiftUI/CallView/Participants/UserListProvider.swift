//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo

public protocol UserListProvider {

    func loadNextUsers(pagination: Pagination) async throws -> [User]
}

public class StreamUserListProvider: UserListProvider {

    public init() {}

    public func loadNextUsers(pagination: Pagination) async throws -> [User] {
        // TODO: implement querying of available users.
        []
    }
}

public struct Pagination: Sendable {

    public let pageSize: Int
    public let offset: Int
}
