//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        final class CustomObject {
            private var client: StreamVideo
            private let apiKey: String = "" // The API key can be found in the Credentials section
            private let token: String = "" // The Token can be found in the Credentials section
            private let userId: String = "" // The User Id can be found in the Credentials section
            private let callId: String = "" // The CallId can be found in the Credentials section

            init() {
                let user = User(
                    id: userId,
                    name: "Obi-Wan Kenobi", // name and imageURL are used in the UI
                    imageURL: .init(string: "https://picsum.photos/120")
                )

                // Initialize Stream Video client
                self.client = StreamVideo(
                    apiKey: apiKey,
                    user: user,
                    token: .init(stringLiteral: token)
                )
            }
        }
    }

    container {
        final class CustomObject {
            var client: StreamVideo { streamVideo }
            var call: Call?

            init() {
                self.call = client.call(callType: "audio_room", callId: callId)
            }
        }
    }

    asyncContainer {
        try await call.join(
            create: true,
            options: .init(
                members: [
                    .init(userId: "john_smith"),
                    .init(userId: "jane_doe")
                ],
                custom: [
                    "title": .string("SwiftUI heads"),
                    "description": .string("Talking about SwiftUI")
                ]
            )
        )
    }

    asyncContainer {
        let response = try await call.request(permissions: [.sendAudio])
    }

    asyncContainer {
        if let request = call.state.permissionRequests.first {
            // reject it
            request.reject()

            // grant it
            try await call.grant(request: request)
        }
    }

    container {
        struct AudioroomsApp: App {
            @State var call: Call
            @ObservedObject var state: CallState
            @State private var callCreated: Bool = false

            private var client: StreamVideo
            private let apiKey: String = "" // The API key can be found in the Credentials section
            private let userId: String = "" // The User Id can be found in the Credentials section
            private let token: String = "" // The Token can be found in the Credentials section
            private let callId: String = "" // The CallId can be found in the Credentials section

            init() {
                let user = User(
                    id: userId,
                    name: "Obi-Wan Kenobi", // name and imageURL are used in the UI
                    imageURL: .init(string: "https://picsum.photos/120")
                )

                // Initialize Stream Video client
                self.client = StreamVideo(
                    apiKey: apiKey,
                    user: user,
                    token: .init(stringLiteral: token)
                )

                // Initialize the call object
                let call = client.call(callType: "audio_room", callId: callId)

                self.call = call
                self.state = call.state
            }

            var body: some Scene {
                WindowGroup {
                    VStack {
                        if callCreated {
                            DescriptionView(
                                title: call.state.custom["title"]?.stringValue,
                                description: call.state.custom["description"]?.stringValue,
                                participants: call.state.participants
                            )
                            ParticipantsView(
                                participants: call.state.participants
                            )
                            Spacer()
                            ControlsView(call: call, state: state)
                        } else {
                            Text("loading...")
                        }
                    }.task {
                        Task {
                            guard !callCreated else { return }
                            try await call.join(
                                create: true,
                                options: .init(
                                    members: [
                                        .init(userId: "john_smith"),
                                        .init(userId: "jane_doe")
                                    ],
                                    custom: [
                                        "title": .string("SwiftUI heads"),
                                        "description": .string("talking about SwiftUI")
                                    ]
                                )
                            )
                            callCreated = true
                        }
                    }
                }
            }
        }

        struct ControlsView: View {
            var call: Call
            @ObservedObject var state: CallState

            var body: some View {
                HStack {
                    MicButtonView(microphone: call.microphone)
                    LiveButtonView(call: call, state: state)
                }
            }
        }

        struct DescriptionView: View {
            var title: String?
            var description: String?
            var participants: [CallParticipant]

            var body: some View {
                VStack {
                    VStack {
                        Text("\(title ?? "")")
                            .font(.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .padding([.bottom], 8)

                        Text("\(description ?? "")")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                            .padding([.bottom], 4)

                        Text("\(participants.count) participants")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.padding([.leading, .trailing])
                }
            }
        }

        struct LiveButtonView: View {
            var call: Call
            @ObservedObject var state: CallState

            var body: some View {
                if state.backstage {
                    Button {
                        Task {
                            try await call.goLive()
                        }
                    } label: {
                        Text("Go Live")
                    }
                    .buttonStyle(.borderedProminent).tint(.green)
                } else {
                    Button {
                        Task {
                            try await call.stopLive()
                        }
                    } label: {
                        Text("Stop live")
                    }
                    .buttonStyle(.borderedProminent).tint(.red)
                }
            }
        }

        struct MicButtonView: View {
            @ObservedObject var microphone: MicrophoneManager

            var body: some View {
                Button {
                    Task {
                        try await microphone.toggle()
                    }
                } label: {
                    Image(systemName: microphone.status == .enabled ? "mic.circle" : "mic.slash.circle")
                        .foregroundColor(microphone.status == .enabled ? .red : .primary)
                        .font(.title)
                }
            }
        }

        struct ParticipantsView: View {
            var participants: [CallParticipant]

            var body: some View {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                    ForEach(participants) {
                        ParticipantView(participant: $0)
                    }
                }
            }
        }

        struct ParticipantView: View {
            var participant: CallParticipant

            var body: some View {
                VStack {
                    ZStack {
                        Circle()
                            .fill(participant.isSpeaking ? .green : .white)
                            .frame(width: 68, height: 68)
                        AsyncImage(
                            url: participant.profileImageURL,
                            content: { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 64, maxHeight: 64)
                                    .clipShape(Circle())
                            },
                            placeholder: {
                                Image(systemName: "person.crop.circle").font(.system(size: 60))
                            }
                        )
                    }
                    Text("\(participant.name)")
                }
            }
        }

        struct PermissionRequestsView: View {
            var call: Call
            @ObservedObject var state: CallState

            var body: some View {
                if let request = state.permissionRequests.first {
                    HStack {
                        Text("\(request.user.name) requested to \(request.permission)")
                        Button {
                            Task {
                                try await call.grant(request: request)
                            }
                        } label: {
                            Label("", systemImage: "hand.thumbsup.circle").tint(.green)
                        }
                        Button(action: request.reject) {
                            Label("", systemImage: "hand.thumbsdown.circle.fill").tint(.red)
                        }
                    }
                }
            }
        }
    }
}
