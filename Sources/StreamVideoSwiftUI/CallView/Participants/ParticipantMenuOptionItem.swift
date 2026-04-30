//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

/// A single row in the video participant ellipsis menu, for app-defined actions merged with stock items.
///
/// Equality and hashing use ``id`` only so stable row identity does not depend on the action closure or title.
/// Duplicate `id` values in one menu produce undefined SwiftUI behavior—use distinct ids when titles or actions differ.
public struct ParticipantMenuOptionItem: Hashable {

    public let id: String
    public let title: String

    private let action: () -> Void

    public init(id: String, title: String, action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.action = action
    }

    public func perform() {
        action()
    }

    public static func == (lhs: ParticipantMenuOptionItem, rhs: ParticipantMenuOptionItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
