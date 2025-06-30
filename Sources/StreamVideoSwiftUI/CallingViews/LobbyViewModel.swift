//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import StreamVideo
import SwiftUI

@MainActor
public class LobbyViewModel: ObservableObject, @unchecked Sendable {
    @Injected(\.callAudioRecorder) private var callAudioRecorder

    let camera: Any?
    private var imagesTask: Task<Void, Never>?
    private let disposableBag = DisposableBag()

    @Published public var viewFinderImage: Image?
    @Published public var participants: [User]
    @Published public var audioOn: Bool {
        didSet { didUpdate(audioOn: audioOn) }
    }

    @Published public var videoOn: Bool {
        didSet { didUpdate(videoOn: videoOn) }
    }

    @Published public var cameraPosition: CameraPosition
    @Published public var audioLevels: [Float]
    @Published public var isSilent: Bool

    private let call: Call
    private let callViewModel: CallViewModel
    private let microphoneChecker: MicrophoneChecker
    private let onJoinCallTap: () -> Void
    private let onCloseLobbyTap: () -> Void

    public init(
        callType: String,
        callId: String,
        callViewModel: CallViewModel,
        onJoinCallTap: @escaping () -> Void,
        onCloseLobbyTap: @escaping () -> Void
    ) {
        let call = InjectedValues[\.streamVideo].call(
            callType: callType,
            callId: callId
        )
        self.call = call
        self.callViewModel = callViewModel
        audioOn = callViewModel.callSettings.audioOn
        videoOn = callViewModel.callSettings.videoOn
        cameraPosition = callViewModel.callSettings.cameraPosition

        let microphoneChecker = MicrophoneChecker()
        self.microphoneChecker = microphoneChecker
        audioLevels = microphoneChecker.audioLevels
        isSilent = microphoneChecker.isSilent

        self.onJoinCallTap = onJoinCallTap
        self.onCloseLobbyTap = onCloseLobbyTap

        participants = call.state.participants.map(\.user)
        if #available(iOS 14.0, *) {
            camera = Camera()
        } else {
            camera = nil
        }

        loadCurrentMembers()
        subscribeForCallJoinUpdates()
        subscribeForCallLeaveUpdates()

        microphoneChecker
            .$audioLevels
            .receive(on: DispatchQueue.main)
            .assign(to: \.audioLevels, onWeak: self)
            .store(in: disposableBag)

        microphoneChecker
            .$audioLevels
            .compactMap { [weak microphoneChecker] _ in microphoneChecker?.isSilent ?? false }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.isSilent, onWeak: self)
            .store(in: disposableBag)

        callViewModel
            .$callSettings
            .map(\.audioOn)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.audioOn, onWeak: self)
            .store(in: disposableBag)

        callViewModel
            .$callSettings
            .map(\.videoOn)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.videoOn, onWeak: self)
            .store(in: disposableBag)

        callViewModel
            .$callSettings
            .map(\.cameraPosition)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: \.cameraPosition, onWeak: self)
            .store(in: disposableBag)

        call
            .state
            .$participants
            .removeDuplicates()
            .map { $0.map(\.user) }
            .assign(to: \.participants, onWeak: self)
            .store(in: disposableBag)

        if #available(iOS 14.0, *), let camera = camera as? Camera {
            Task(disposableBag: disposableBag) { @MainActor [weak self] in
                guard let self else { return }
                for await image in camera.previewStream {
                    viewFinderImage = image.image
                }
            }
        }
    }

    public func startCamera(front: Bool) {
        if #available(iOS 14.0, *), let camera = camera as? Camera {
            Task(disposableBag: disposableBag) {
                await camera.start()
            }
        }
    }

    public func stopCamera() {
        if #available(iOS 14.0, *), let camera = camera as? Camera {
            camera.stop()
        }
    }

    public func cleanUp() {
        disposableBag.removeAll()
    }

    public func didTapJoin() {
        onJoinCallTap()
    }

    public func didTapClose() {
        if callAudioRecorder.isRecording {
            Task(disposableBag: disposableBag) { [weak callAudioRecorder] in
                await callAudioRecorder?.stopRecording()
            }
        }
        stopCamera()
        cleanUp()
        onCloseLobbyTap()
    }

    public func toggleMicrophoneEnabled() {
        callViewModel.toggleMicrophoneEnabled()
    }

    public func toggleCameraEnabled() {
        callViewModel.toggleCameraEnabled()
    }

    // MARK: - private

    private func loadCurrentMembers() {
        Task {
            do {
                let response = try await call.get()
                withAnimation {
                    participants = response.call.session?.participants.map(\.user.toUser) ?? []
                }
            } catch {
                log.error(error)
            }
        }
    }

    private func subscribeForCallJoinUpdates() {
        call
            .eventPublisher(for: CallSessionParticipantJoinedEvent.self)
            .map(\.participant.user.toUser)
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] user in
                withAnimation { [weak self] in
                    self?.participants.append(user)
                }
            }
            .store(in: disposableBag)
    }

    private func subscribeForCallLeaveUpdates() {
        call
            .eventPublisher(for: CallSessionParticipantLeftEvent.self)
            .map(\.participant.user.toUser)
            .sinkTask(storeIn: disposableBag) { @MainActor [weak self] user in
                guard let self else {
                    return
                }
                var indexToRemove: Int?
                for (index, participant) in participants.enumerated() {
                    if participant.id == user.id {
                        indexToRemove = index
                        break
                    }
                }
                withAnimation { [weak self] in
                    if let indexToRemove {
                        self?.participants.remove(at: indexToRemove)
                    }
                }
            }
            .store(in: disposableBag)
    }

    private func didUpdate(audioOn: Bool) {
        if audioOn, !callAudioRecorder.isRecording {
            Task(disposableBag: disposableBag) { [weak callAudioRecorder] in
                await callAudioRecorder?.startRecording(ignoreActiveCall: true)
            }
        } else if !audioOn, callAudioRecorder.isRecording {
            Task(disposableBag: disposableBag) { [weak callAudioRecorder] in
                await callAudioRecorder?.stopRecording()
            }
        }
    }

    private func didUpdate(videoOn: Bool) {
        if videoOn {
            startCamera(front: cameraPosition == .front)
        } else if !videoOn {
            stopCamera()
        }
    }
}

private extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}
