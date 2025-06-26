//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@MainActor
public struct VideoCallParticipantOptionsModifier: ViewModifier {

    @Injected(\.appearance) var appearance

    @State private var presentActionSheet: Bool = false

    public var participant: CallParticipant
    public var call: Call?

    public init(
        participant: CallParticipant,
        call: Call?
    ) {
        self.participant = participant
        self.call = call
    }

    private var elements: [(title: String, action: () -> Void)] {
        var result = [(title: String, action: () -> Void)]()

        if participant.isPinned {
            result.append((title: L10n.Call.Current.unpinUser, action: { unpin() }))
        } else {
            result.append((title: L10n.Call.Current.pinUser, action: { pin() }))
        }

        if call?.state.ownCapabilities.contains(.pinForEveryone) == true {
            if participant.isPinnedRemotely {
                result.append((title: L10n.Call.Current.unpinForEveryone, action: { unpinForEveryone() }))
            } else {
                result.append((title: L10n.Call.Current.pinForEveryone, action: { pinForEveryone() }))
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
            .background(appearance.colors.participantInfoBackgroundColor)
            .clipShape(Circle())
    }

    @ViewBuilder
    private var contentView: some View {
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

    private func unpin() {
        Task {
            do {
                try await call?.unpin(
                    sessionId: participant.sessionId
                )
            } catch {
                log.error(error)
            }
        }
    }

    private func pin() {
        Task {
            do {
                try await call?.pin(
                    sessionId: participant.sessionId
                )
            } catch {
                log.error(error)
            }
        }
    }

    private func unpinForEveryone() {
        Task {
            do {
                _ = try await call?.unpinForEveryone(
                    userId: participant.userId,
                    sessionId: participant.id
                )
            } catch {
                log.error(error)
            }
        }
    }

    private func pinForEveryone() {
        Task {
            do {
                _ = try await call?.pinForEveryone(
                    userId: participant.userId,
                    sessionId: participant.id
                )
            } catch {
                log.error(error)
            }
        }
    }
}
