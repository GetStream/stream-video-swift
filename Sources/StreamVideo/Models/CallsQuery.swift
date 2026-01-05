//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines a query to retrieve a list of calls from the server, with specified page size, sort parameters,
/// filters and watch flag.
public struct CallsQuery {
    /// The number of calls to return in a single page.
    public let pageSize: Int
    /// An array of sort parameters to apply to the calls list.
    public let sortParams: [CallSortParam]
    /// An optional dictionary of filters to apply to the calls list.
    public let filters: [String: RawJSON]?
    /// A flag that indicates whether the query should watch for changes to the calls list.
    public let watch: Bool
    
    /// Initializes a new instance of `CallsQuery`.
    /// - Parameters:
    ///  - pageSize: The number of calls to return in a single page. Default value is `25`.
    ///  - sortParams: An array of sort parameters to apply to the calls list.
    ///  - filters: An optional dictionary of filters to apply to the calls list.
    ///  - watch: A flag that indicates whether the query should watch for changes to the calls list.
    public init(
        pageSize: Int = 25,
        sortParams: [CallSortParam],
        filters: [String: RawJSON]? = nil,
        watch: Bool
    ) {
        self.pageSize = pageSize
        self.sortParams = sortParams
        self.filters = filters
        self.watch = watch
    }
}

/// Defines a sort parameter for calls.
public struct CallSortParam {
    /// The direction of the sort.
    public let direction: CallSortDirection
    /// The field to sort by.
    public let field: CallSortField
    
    /// Initializes a new instance of `CallSortParam`.
    /// - Parameters:
    ///  - direction: The direction of the sort.
    ///  - field: The field to sort by.
    public init(direction: CallSortDirection, field: CallSortField) {
        self.direction = direction
        self.field = field
    }
}

/// Defines the sort direction for calls.
public enum CallSortDirection: Int {
    case ascending = 1
    case descending = -1
}

/// Defines the field to sort calls by.
public struct CallSortField: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension CallSortField {
    /// The sort field for the call start time.
    static let startsAt: Self = "starts_at"
    /// The sort field for the call creation time.
    static let createdAt: Self = "created_at"
    /// The sort field for the call update time.
    static let updatedAt: Self = "updated_at"
    /// The sort field for the call end time.
    static let endedAt: Self = "ended_at"
    /// The sort field for the call type.
    static let type: Self = "type"
    /// The sort field for the call id.
    static let id: Self = "id"
    /// The sort field for the call cid.
    static let cid: Self = "cid"
}

public extension SortParamRequest {
    static func ascending(_ field: String) -> SortParamRequest {
        .init(direction: 1, field: field)
    }

    static func descending(_ field: String) -> SortParamRequest {
        .init(direction: -1, field: field)
    }
}
