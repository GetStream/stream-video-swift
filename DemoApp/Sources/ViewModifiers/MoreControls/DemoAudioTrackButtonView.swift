//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

struct DemoAudioTrackButtonView: View {
    @Injected(\.audioPlayer) var audioPlayer: AudioTrackPlayer

    @State private var isPlaying: Bool = AudioTrackPlayer.currentValue.isPlaying
    @State private var track: AudioTrackPlayer.Track? = AudioTrackPlayer.currentValue.track

    var body: some View {
        Menu {
            Button {
                audioPlayer.stop()
            } label: {
                Label {
                    Text("None")
                } icon: {
                    if track == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(AudioTrackPlayer.Track.allCases, id: \.self) { track in
                Button {
                    if self.track == track {
                        audioPlayer.stop()
                    } else {
                        audioPlayer.play(track)
                    }
                } label: {
                    Label {
                        Text(track.rawValue)
                    } icon: {
                        if self.track == track {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            DemoMoreControlListButtonView(
                action: {},
                label: "In-App audio"
            ) {
                Image(
                    systemName: isPlaying ? "pause.circle" : "play.circle"
                )
            }
        }
        .onReceive(audioPlayer.$isPlaying.receive(on: DispatchQueue.main)) { isPlaying = $0 }
        .onReceive(audioPlayer.$track.receive(on: DispatchQueue.main)) { track = $0 }
    }
}
