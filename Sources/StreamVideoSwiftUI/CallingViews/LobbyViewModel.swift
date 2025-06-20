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

    private let camera: CameraAdapter
    private var imagesTask: Task<Void, Never>?
    private let disposableBag = DisposableBag()

    @Published public var viewfinderImage: Image?
    @Published public var participants = [User]()
    
    private let call: Call
    
    public init(callType: String, callId: String) {
        call = InjectedValues[\.streamVideo].call(
            callType: callType,
            callId: callId
        )
        camera = .init(cameraPosition: call.state.callSettings.cameraPosition)
        loadCurrentMembers()
        subscribeForCallJoinUpdates()
        subscribeForCallLeaveUpdates()

        camera
            .$image
            .map(\.?.image)
            .receive(on: DispatchQueue.main)
            .assign(to: \.viewfinderImage, onWeak: self)
            .store(in: disposableBag)
    }

    public func startCamera(front: Bool) {
        Task {
            await self.camera.start()
        }
    }
    
    public func stopCamera() {
        camera.stop()
        Task { @MainActor in
            viewfinderImage = nil
        }
    }
    
    public func cleanUp() {
        disposableBag.removeAll()
        camera.stop()
        Task {
            await callAudioRecorder.stopRecording()
        }
    }

    public func didUpdate(callSettings: CallSettings) async {
        if callSettings.audioOn {
            await callAudioRecorder.startRecording(ignoreActiveCall: true)
        } else {
            await callAudioRecorder.stopRecording()
        }

        if callSettings.videoOn {
            startCamera(front: callSettings.cameraPosition == .front)
        } else {
            stopCamera()
        }
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
}

private extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}
