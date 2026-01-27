//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        let response = try await call.sendReaction(type: "fireworks")
    }

    asyncContainer {
        let response = try await call.sendReaction(
            type: "raise-hand",
            custom: ["mycustomfield": "hello"],
            emojiCode: ":smile:"
        )
    }

    asyncContainer {
        let response = try await call.sendCustomEvent(["type": .string("draw"), "x": .number(10), "y": .number(20)])
    }
    
    asyncContainer {
        for await event in call.subscribe(for: CallReactionEvent.self) {
            // handle reaction event
        }
    }

    container {
        struct ReactionsView: View {
            let call: Call
            @State private var showReactionPicker = false
            @State private var displayedReactions: [DisplayedReaction] = []

            let reactions = ["👍", "❤️", "😂", "🎉", "🔥", "👏"]

            var body: some View {
                ZStack {
                    // Floating reactions animation
                    ForEach(displayedReactions, id: \.id) { reaction in
                        Text(reaction.emoji)
                            .font(.largeTitle)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Reaction button
                    VStack {
                        Spacer()
                        Button {
                            showReactionPicker.toggle()
                        } label: {
                            Image(systemName: "face.smiling")
                                .font(.title2)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                }
                .sheet(isPresented: $showReactionPicker) {
                    ReactionPickerView(reactions: reactions) { emoji in
                        sendReaction(emoji)
                        showReactionPicker = false
                    }
                    .presentationDetents([.height(100)])
                }
                .task {
                    await listenToReactions()
                }
            }

            private func sendReaction(_ emoji: String) {
                Task {
                    try await call.sendReaction(type: "default", emojiCode: emoji)
                }
            }

            private func listenToReactions() async {
                for await event in call.subscribe(for: CallReactionEvent.self) {
                    let reaction = DisplayedReaction(
                        id: UUID(),
                        emoji: event.reaction.emojiCode ?? "👍",
                        userId: event.reaction.user.id
                    )

                    await MainActor.run {
                        withAnimation {
                            displayedReactions.append(reaction)
                        }
                    }

                    // Remove after animation
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        withAnimation {
                            displayedReactions.removeAll { $0.id == reaction.id }
                        }
                    }
                }
            }
        }

        struct DisplayedReaction: Identifiable {
            let id: UUID
            let emoji: String
            let userId: String
        }

        struct ReactionPickerView: View {
            let reactions: [String]
            let onSelect: (String) -> Void

            var body: some View {
                HStack(spacing: 20) {
                    ForEach(reactions, id: \.self) { emoji in
                        Button {
                            onSelect(emoji)
                        } label: {
                            Text(emoji)
                                .font(.largeTitle)
                        }
                    }
                }
                .padding()
            }
        }
    }
}
