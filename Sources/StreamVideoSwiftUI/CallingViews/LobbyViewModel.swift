//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import StreamVideo
import SwiftUI

@MainActor
public class LobbyViewModel: ObservableObject, @unchecked Sendable {
    @Injected(\.callAudioRecorder) private var callAudioRecorder

    private let camera: Any
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
        if #available(iOS 14, *) {
            camera = Camera()
            imagesTask = Task {
                await handleCameraPreviews()
            }
        } else {
            camera = NSObject()
        }
        loadCurrentMembers()
        subscribeForCallJoinUpdates()
        subscribeForCallLeaveUpdates()
    }
    
    @available(iOS 14, *)
    func handleCameraPreviews() async {
        let imageStream = (camera as? Camera)?.previewStream.dropFirst()
            .map(\.image)
        
        guard let imageStream = imageStream else { return }

        for await image in imageStream {
            await MainActor.run {
                viewfinderImage = image
            }
        }
    }
    
    public func startCamera(front: Bool) {
        if #available(iOS 14, *) {
            if front {
                (camera as? Camera)?.switchCaptureDevice()
            }
            Task {
                await (camera as? Camera)?.start()
            }
        }
    }
    
    public func stopCamera() {
        imagesTask?.cancel()
        imagesTask = nil
        if #available(iOS 14, *) {
            (camera as? Camera)?.stop()
        }
    }
    
    public func cleanUp() {
        disposableBag.removeAll()
        callAudioRecorder.stopRecording()
    }

    public func didUpdate(callSettings: CallSettings) {
        if callSettings.audioOn {
            callAudioRecorder.startRecording(ignoreActiveCall: true)
        } else {
            callAudioRecorder.stopRecording()
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
