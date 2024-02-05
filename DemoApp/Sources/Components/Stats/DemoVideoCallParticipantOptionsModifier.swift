//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
public struct DemoVideoCallParticipantOptionsModifier: ViewModifier {

    @Injected(\.appearance) var appearance

    @State private var presentActionSheet: Bool = false
    @State private var presentStats = false

    var participant: CallParticipant
    var call: Call?

    private var elements: [(title: String, action: () -> Void)] {
        var result = [(title: String, action: () -> Void)]()

        if call != nil {
            result.append((title: "Stats", action: { presentStats = true }))
        }

        if participant.isPinned {
            result.append((title: "Unpin user", action: { unpin() }))
        } else {
            result.append((title: "Pin user", action: { pin() }))
        }

        if call?.state.ownCapabilities.contains(.pinForEveryone) == true {
            if participant.isPinnedRemotely {
                result.append((title: "Unpin for everyone", action: { unpinForEveryone() }))
            } else {
                result.append((title: "Pin for everyone", action: { pinForEveryone() }))
            }
        }

        return result
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                TopLeftView {
                    contentView
                }
                .padding(4)
            )
    }

    @ViewBuilder
    private var optionsButtonView: some View {
        Image(systemName: "ellipsis")
            .foregroundColor(.white)
            .padding(8)
            .background(Color.black.opacity(0.6))
            .clipShape(Circle())
    }

    @ViewBuilder
    private var contentView: some View {
        withStatsPopoverIfAvailable {
            if #available(iOS 14.0, *) {
                Menu {
                    ForEach(elements, id: \.title) { element in
                        Button(
                            action: element.action,
                            label: { Text(element.title) }
                        )
                    }
                } label: { optionsButtonView }
            } else {
                Button {
                    presentActionSheet.toggle()
                } label: {
                    optionsButtonView
                }
                .actionSheet(isPresented: $presentActionSheet) {
                    ActionSheet(
                        title: Text("\(participant.name)"),
                        buttons: elements
                            .map { ActionSheet.Button.default(Text($0.title), action: $0.action) } + [ActionSheet.Button.cancel()]
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func withStatsPopoverIfAvailable(
        @ViewBuilder _ content: () -> some View
    ) -> some View {
        if let call = call {
            content()
                .popover(isPresented: $presentStats) {
                    NavigationView {
                        Group {
                            GeometryReader { proxy in
                                ParticipantStatsView(
                                    call: call,
                                    participant: participant,
                                    presentationBinding: $presentStats,
                                    availableFrame: proxy.frame(in: .global)
                                )
                            }
                        }
                        .padding()
                    }
                    .frame(minWidth: 300, minHeight: 400)
                }
        } else {
            content()
        }
    }

    private func unpin() {
        Task {
            try await call?.unpin(
                sessionId: participant.sessionId
            )
        }
    }

    private func pin() {
        Task {
            try await call?.pin(
                sessionId: participant.sessionId
            )
        }
    }

    private func unpinForEveryone() {
        Task {
            try await call?.unpinForEveryone(
                userId: participant.userId,
                sessionId: participant.id
            )
        }
    }

    private func pinForEveryone() {
        Task {
            try await call?.pinForEveryone(
                userId: participant.userId,
                sessionId: participant.id
            )
        }
    }
}

extension View {

    @ViewBuilder
    func participantStats(
        call: Call?,
        participant: CallParticipant
    ) -> some View {
        modifier(DemoVideoCallParticipantOptionsModifier(participant: participant, call: call))
    }
}
