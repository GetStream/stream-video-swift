//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import StreamWebRTC

final class StreamRTCStaticVideoSource: @unchecked Sendable {

    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                beginRenderingLoop()
            } else {
                stopRenderingLoop()
            }
        }
    }

    var participant: CallParticipant? {
        didSet {
            guard participant?.sessionId != oldValue?.sessionId else {
                return
            }
            beginRenderingLoop()
        }
    }

    var contentSize: CGSize = .init(width: 640, height: 480)

    var contentProvider: (CallParticipant, CGSize) async -> CVPixelBuffer? = {
        participant,
            size in
        await Task { @MainActor in
            PictureInPictureParticipantImageView(imageURL: participant.profileImageURL) {
                DefaultViewFactory.shared.makeUserAvatar(
                    participant.user,
                    with: .init(size: 0) {
                        AnyView(
                            CircledTitleView(
                                title: participant.name.isEmpty ? participant.id : String(participant.name.uppercased().first!),
                                size: 0
                            )
                        )
                    }
                )
            }
            .frame(width: size.width, height: size.height)
            .toPixelBuffer
        }.value
    }

    private var renderingSubject: PassthroughSubject<RTCVideoFrame, Never> = .init()
    var renderingPublisher: AnyPublisher<RTCVideoFrame, Never> {
        renderingSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private let framesPerSecond: Double = 15
    private let serialQueue = SerialActorQueue()
    private var renderingCancellable: AnyCancellable?

    // MARK: - Private helpers

    private func beginRenderingLoop() {

        serialQueue.async { [weak self] in
            self?.renderingCancellable?.cancel()

            guard let self, isEnabled, let participant else {
                return
            }

            renderingCancellable = Timer
                .publish(every: 1.0 / framesPerSecond, on: .main, in: .default)
                .autoconnect()
                .map { _ in () }
                .sinkTask(queue: serialQueue) { [weak self] in await self?.publishFrame() }

            log.debug(
                "Static frame generation started for participant:\(participant.name).",
                subsystems: .pictureInPicture
            )
        }
    }

    private func stopRenderingLoop() {
        serialQueue.cancelAll()

        log.debug(
            "Static frame generation stopped.",
            subsystems: .pictureInPicture
        )
    }

    private func publishFrame() async {
        guard
            let participant
        else {
            return
        }

        guard let content = await contentProvider(participant, contentSize) else {
            return
        }

        renderingSubject
            .send(frame(from: content))
    }

    private func frame(from content: CVPixelBuffer) -> RTCVideoFrame {
        .init(
            buffer: RTCCVPixelBuffer(pixelBuffer: content),
            rotation: ._0,
            timeStampNs: 0
        )
    }
}

extension StreamRTCStaticVideoSource: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamRTCStaticVideoSource = .init()
}

extension InjectedValues {

    var staticVideoSource: StreamRTCStaticVideoSource {
        get { Self[StreamRTCStaticVideoSource.self] }
        set { Self[StreamRTCStaticVideoSource.self] = newValue }
    }
}

import SwiftUI

extension View {

    @MainActor
    var toPixelBuffer: CVPixelBuffer? {
        guard #available(iOS 16.0, *) else {
            return nil
        }
        let renderer = ImageRenderer(content: self)
        if let image = renderer.uiImage {
            return .build(from: image)
        } else {
            return nil
        }
    }
}

extension CVBuffer: @unchecked @retroactive Sendable {}
