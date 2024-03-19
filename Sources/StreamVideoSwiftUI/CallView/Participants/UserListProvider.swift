//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo

public protocol UserListProvider: Sendable {

    func loadNextUsers(pagination: Pagination) async throws -> [User]
}

public final class StreamUserListProvider: UserListProvider {

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
