//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

struct AudioVolumeIndicatorContainerView: View {

    final class ViewModel: ObservableObject {
        @Published var audioOn: Bool = false
        @Published var audioLevels: [Float] = []
        @Published var isSilent: Bool = false

        private let disposableBag = DisposableBag()

        init(
            audioOn: Bool,
            audioOnPublisher: AnyPublisher<Bool, Never>,
            audioLevels: [Float],
            audioLevelsPublisher: AnyPublisher<[Float], Never>,
            isSilent: Bool,
            isSilentPublisher: AnyPublisher<Bool, Never>
        ) {
            self.audioOn = audioOn
            self.audioLevels = audioLevels
            self.isSilent = isSilent

            audioOnPublisher
                .removeDuplicates()
                .throttle(
                    for: .milliseconds(Int(ScreenPropertiesAdapter.currentValue.refreshRate)),
                    scheduler: RunLoop.main,
                    latest: true
                )
                .receive(on: DispatchQueue.main)
                .assign(to: \.audioOn, onWeak: self)
                .store(in: disposableBag)

            audioLevelsPublisher
                .receive(on: DispatchQueue.main)
                .assign(to: \.audioLevels, onWeak: self)
                .store(in: disposableBag)

            isSilentPublisher
                .removeDuplicates()
                .throttle(
                    for: .milliseconds(Int(ScreenPropertiesAdapter.currentValue.refreshRate)),
                    scheduler: RunLoop.main,
                    latest: true
                )
                .receive(on: DispatchQueue.main)
                .assign(to: \.isSilent, onWeak: self)
                .store(in: disposableBag)
        }
    }

    @Injected(\.images) var images
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: ViewModel

    var maxHeight: Float

    init(
        audioOn: Bool,
        audioOnPublisher: AnyPublisher<Bool, Never>,
        audioLevels: [Float],
        audioLevelsPublisher: AnyPublisher<[Float], Never>,
        isSilent: Bool,
        isSilentPublisher: AnyPublisher<Bool, Never>,
        maxHeight: Float
    ) {
        viewModel = .init(
            audioOn: audioOn,
            audioOnPublisher: audioOnPublisher,
            audioLevels: audioLevels,
            audioLevelsPublisher: audioLevelsPublisher,
            isSilent: isSilent,
            isSilentPublisher: isSilentPublisher
        )
        self.maxHeight = maxHeight
    }

    var body: some View {
        Group {
            if viewModel.audioOn, !viewModel.isSilent {
                AudioVolumeIndicator(
                    audioLevels: viewModel.audioLevels,
                    maxHeight: maxHeight,
                    minValue: 0,
                    maxValue: 1
                )
            } else {
                images.micTurnOff
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: CGFloat(maxHeight))
                    .foregroundColor(colors.inactiveCallControl)
            }
        }
        .debugViewRendering()
    }
}
