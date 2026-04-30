//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import UIKit

/// Per-participant video aspect override for Demo; layout default comes from the SDK call site.
@MainActor
final class DemoParticipantTileState: ObservableObject {

    static let shared = DemoParticipantTileState()

    private var layoutDefaultByParticipantId: [String: UIView.ContentMode] = [:]
    private var overrideContentMode: [String: UIView.ContentMode] = [:]

    private init() {}

    func noteLayoutDefault(_ mode: UIView.ContentMode, for participantId: String) {
        layoutDefaultByParticipantId[participantId] = mode
    }

    func layoutDefault(for participantId: String) -> UIView.ContentMode {
        layoutDefaultByParticipantId[participantId] ?? .scaleAspectFill
    }

    func resolvedContentMode(
        for participantId: String,
        layoutFromCallSite: UIView.ContentMode
    ) -> UIView.ContentMode {
        overrideContentMode[participantId] ?? layoutFromCallSite
    }

    func toggleVideoAspectMode(for participantId: String) {
        let layout = layoutDefault(for: participantId)
        let current = resolvedContentMode(for: participantId, layoutFromCallSite: layout)
        let next: UIView.ContentMode = current == .scaleAspectFill ? .scaleAspectFit : .scaleAspectFill
        overrideContentMode[participantId] = next
        objectWillChange.send()
    }
}
