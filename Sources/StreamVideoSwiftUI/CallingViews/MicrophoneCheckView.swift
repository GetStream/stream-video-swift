//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct MicrophoneCheckView: View {
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.streamVideo) var streamVideo

    var audioLevels: [Float]
    var audioLevelsPublisher: AnyPublisher<[Float], Never>

    var audioOn: Bool
    var audioOnPublisher: AnyPublisher<Bool, Never>

    var isSilent: Bool
    var isSilentPublisher: AnyPublisher<Bool, Never>

    var isPinned: Bool

    var maxHeight: Float = 14

    public init(
        viewModel: LobbyViewModel,
        isPinned: Bool,
        maxHeight: Float = 14
    ) {
        self.init(
            audioLevels: viewModel.audioLevels,
            audioLevelsPublisher: viewModel.$audioLevels.eraseToAnyPublisher(),
            audioOn: viewModel.audioOn,
            audioOnPublisher: viewModel.$audioOn.eraseToAnyPublisher(),
            isSilent: viewModel.isSilent,
            isSilentPublisher: viewModel.$isSilent.eraseToAnyPublisher(),
            isPinned: isPinned,
            maxHeight: maxHeight
        )
    }

    public init(
        audioLevels: [Float],
        microphoneOn: Bool,
        isSilent: Bool,
        isPinned: Bool,
        maxHeight: Float = 14
    ) {
        self.init(
            audioLevels: audioLevels,
            audioLevelsPublisher: Just(audioLevels).eraseToAnyPublisher(),
            audioOn: microphoneOn,
            audioOnPublisher: Just(microphoneOn).eraseToAnyPublisher(),
            isSilent: isSilent,
            isSilentPublisher: Just(isSilent).eraseToAnyPublisher(),
            isPinned: isPinned,
            maxHeight: maxHeight
        )
    }

    init(
        audioLevels: [Float],
        audioLevelsPublisher: AnyPublisher<[Float], Never>,
        audioOn: Bool,
        audioOnPublisher: AnyPublisher<Bool, Never>,
        isSilent: Bool,
        isSilentPublisher: AnyPublisher<Bool, Never>,
        isPinned: Bool,
        maxHeight: Float = 14
    ) {
        self.audioLevels = audioLevels
        self.audioLevelsPublisher = audioLevelsPublisher
        self.audioOn = audioOn
        self.audioOnPublisher = audioOnPublisher
        self.isSilent = isSilent
        self.isSilentPublisher = isSilentPublisher
        self.isPinned = isPinned
        self.maxHeight = maxHeight
    }

    public var body: some View {
        HStack(spacing: 4) {
            leadingView
            middleView
            trailingView
        }
        .padding(.all, 2)
        .padding(.horizontal, 4)
        .frame(height: 28)
        .cornerRadius(
            8,
            corners: [.topRight],
            backgroundColor: colors.participantInfoBackgroundColor
        )
    }

    @ViewBuilder
    var leadingView: some View {
        PinnedView(isPinned: isPinned, maxHeight: maxHeight)
    }

    @ViewBuilder
    var middleView: some View {
        UserNameView(name: streamVideo.user.name)
    }

    @ViewBuilder
    var trailingView: some View {
        AudioVolumeIndicatorContainerView(
            audioOn: audioOn,
            audioOnPublisher: audioOnPublisher,
            audioLevels: audioLevels,
            audioLevelsPublisher: audioLevelsPublisher,
            isSilent: isSilent,
            isSilentPublisher: isSilentPublisher,
            maxHeight: maxHeight
        )
    }
}

struct PinnedView: View {
    var isPinned: Bool
    var maxHeight: Float

    var body: some View {
        if isPinned {
            Image(systemName: "pin.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: CGFloat(maxHeight))
                .foregroundColor(.white)
                .padding(.trailing, 4)
        }
    }
}

struct UserNameView: View {
    @Injected(\.fonts) private var fonts

    var name: String

    var body: some View {
        Text(name)
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .font(fonts.caption1)
            .minimumScaleFactor(0.7)
            .accessibility(identifier: "participantName")
    }
}
