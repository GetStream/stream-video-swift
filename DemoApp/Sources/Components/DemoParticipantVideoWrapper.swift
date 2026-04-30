//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import UIKit

/// Wraps the default participant view and applies Demo-only aspect mode overrides.
struct DemoParticipantVideoWrapper: View {

    @ObservedObject private var tileState = DemoParticipantTileState.shared

    var participant: CallParticipant
    var id: String
    var availableFrame: CGRect
    var layoutContentMode: UIView.ContentMode
    var customData: [String: RawJSON]
    var call: Call?

    var body: some View {
        let resolvedMode = tileState.resolvedContentMode(
            for: id,
            layoutFromCallSite: layoutContentMode
        )
        return DefaultViewFactory.shared.makeVideoParticipantView(
            participant: participant,
            id: id,
            availableFrame: availableFrame,
            contentMode: resolvedMode,
            customData: customData,
            call: call
        )
        .id("\(id)-contentMode-\(resolvedMode.rawValue)")
        .onAppear {
            tileState.noteLayoutDefault(layoutContentMode, for: id)
        }
    }
}
