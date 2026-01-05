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
        try await call.startClosedCaptions() // start closed captions
    }

    asyncContainer {
        try await call.stopClosedCaptions() // stop closed captions
    }

    container {
        struct DemoClosedCaptionsView: View {

            @Injected(\.colors) private var colors

            var call: Call
            @State private var items: [CallClosedCaption] = []

            init(_ call: Call) {
                self.call = call
            }

            var body: some View {
                Group {
                    if items.isEmpty {
                        EmptyView()
                    } else {
                        VStack {
                            ForEach(items, id: \.hashValue) { item in
                                HStack(alignment: .top) {
                                    Text(item.speakerId)
                                        .foregroundColor(.init(colors.textLowEmphasis))

                                    Text(item.text)
                                        .lineLimit(3)
                                        .foregroundColor(colors.text)
                                        .frame(maxWidth: .infinity)
                                }
                                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .animation(.default, value: items)
                    }
                }
                .onReceive(call.state.$closedCaptions) { items = $0 }
            }
        }
    }

    container {
        let isCaptioningInProgress = call.state.captioning
    }

    container {
        struct DemoCloseCaptionsButtonView: View {

            var call: Call
            @State private var areClosedCaptionsAvailable = false
            @State private var isCaptioning = false

            init(call: Call) {
                self.call = call
                areClosedCaptionsAvailable = (call.state.settings?.transcription.closedCaptionMode ?? .disabled) != .disabled
                    && call.currentUserHasCapability(.startClosedCaptionsCall) == true
                    && call.currentUserHasCapability(.stopClosedCaptionsCall) == true
                isCaptioning = call.state.captioning == true
            }

            var body: some View {
                Group {
                    if areClosedCaptionsAvailable {
                        Button {
                            Task {
                                do {
                                    if isCaptioning {
                                        try await call.stopClosedCaptions()
                                    } else {
                                        try await call.startClosedCaptions()
                                    }
                                } catch {
                                    log.error(error)
                                }
                            }
                        } label: {
                            Label {
                                Text(isCaptioning ? "Disable Closed Captions" : "Closed Captions")
                            } icon: {
                                Image(
                                    systemName: isCaptioning
                                        ? "captions.bubble.fill"
                                        : "captions.bubble"
                                )
                            }
                        }
                        .onReceive(call.state.$captioning) { isCaptioning = $0 }
                    }
                }
                .onReceive(call.state.$settings) {
                    guard let mode = $0?.transcription.closedCaptionMode else {
                        areClosedCaptionsAvailable = false
                        return
                    }
                    areClosedCaptionsAvailable = mode != .disabled
                }
            }
        }
    }

    asyncContainer {
        try await call.create(
            transcription: TranscriptionSettingsRequest(
                closedCaptionMode: .available,
                mode: .available
            )
        )
    }

    asyncContainer {
        await call.updateClosedCaptionsSettings(
            itemPresentationDuration: 2.7, // maximum duration a caption can stay visible(in seconds)
            maxVisibleItems: 2 // maximum number of captions visible at one time
        )
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: "123")
        for await event in call.subscribe(for: ClosedCaptionEvent.self) {
            print("Closed caption event: \(event)")
        }
    }
}
