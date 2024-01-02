//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ParticipantPopoverView<CustomView: View>: View {
    
    var participant: CallParticipant
    var call: Call?
    @Binding var popoverShown: Bool
    var customView: (() -> CustomView)?
    
    public init(
        participant: CallParticipant,
        call: Call?,
        popoverShown: Binding<Bool>,
        customView: (() -> CustomView)? = nil
    ) {
        self.participant = participant
        self.call = call
        self.customView = customView
        _popoverShown = popoverShown
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            if !participant.isPinnedRemotely {
                PopoverButton(
                    title: pinTitle,
                    popoverShown: $popoverShown
                ) {
                    if participant.isPinned {
                        Task {
                            try await call?.unpin(
                                sessionId: participant.sessionId
                            )
                        }
                    } else {
                        Task {
                            try await call?.pin(
                                sessionId: participant.sessionId
                            )
                        }
                    }
                }
            }
            
            if call?.state.ownCapabilities.contains(.pinForEveryone) == true {
                PopoverButton(
                    title: pinForEveryoneTitle,
                    popoverShown: $popoverShown
                ) {
                    if participant.isPinnedRemotely {
                        Task {
                            try await call?.unpinForEveryone(
                                userId: participant.userId,
                                sessionId: participant.id
                            )
                        }
                    } else {
                        Task {
                            try await call?.pinForEveryone(
                                userId: participant.userId,
                                sessionId: participant.id
                            )
                        }
                    }
                }
            }
            
            if let customView {
                customView()
            }
        }
        .padding()
        .modifier(ShadowViewModifier())
    }
    
    private var pinTitle: String {
        participant.isPinned
            ? L10n.Call.Current.unpinUser
            : L10n.Call.Current.pinUser
    }
    
    private var pinForEveryoneTitle: String {
        participant.isPinnedRemotely
            ? L10n.Call.Current.unpinForEveryone
            : L10n.Call.Current.pinForEveryone
    }
}

extension ParticipantPopoverView where CustomView == EmptyView {
    public init(
        participant: CallParticipant,
        call: Call?,
        popoverShown: Binding<Bool>
    ) {
        self.init(participant: participant, call: call, popoverShown: popoverShown) {
            EmptyView()
        }
    }
}
