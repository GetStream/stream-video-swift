//
//  DemoMoreAudioBitrateProfileButtonView.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 6/10/25.
//

import Foundation
import SwiftUI
import StreamVideo

struct DemoMoreAudioBitrateProfileButtonView: View {
    @Injected(\.colors) private var colors

    private var call: Call?
    @State private var selected: AudioBitrateProfile = .voiceStandard

    init(call: Call?) {
        self.call = call
    }

    var body: some View {
        if isSupported {
            contentView
        }
    }

    // MARK: - Private Helpers

    private var isSupported: Bool {
        // TODO: add check for
        call != nil
    }

    @ViewBuilder
    private var contentView: some View {
        Menu {
            ForEach(AudioBitrateProfile.allCases, id: \.rawValue) {
                view(for: $0)
            }
        } label: {
            Label {
                Text("Audio Profile")
            } icon: {
                Image(systemName: "dot.radiowaves.left.and.right")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .frame(height: 40)
        .foregroundColor(colors.white)
        .background(Color(colors.participantBackground))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func view(for item: AudioBitrateProfile) -> some View {
        Button {
            selected = item
        } label: {
            Label {
                Text(item.title)
            } icon: {
                if selected == item {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

extension AudioBitrateProfile {
    static var allCases: [AudioBitrateProfile] = [
        .voiceStandard,
        .voiceHighQuality,
        .musicHighQuality
    ]
    var title: String {
        switch self {
        case .voiceStandard:
            return "Voice Standard"
        case .voiceHighQuality:
            return "Voice HighQuality"
        case .musicHighQuality:
            return "Music HighQuality"
        }
    }
}
