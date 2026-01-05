//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {

    viewContainer {
        YourHostView()
            .snapshot(
                trigger: snapshotTrigger,
                snapshotHandler: { _ in
                    // Further processing ...
                }
            )
    }

    container {
        final class StreamSnapshotTrigger: SnapshotTriggering {
            lazy var binding: Binding<Bool> = Binding<Bool>(
                get: { [weak self] in
                    self?.currentValueSubject.value ?? false
                },
                set: { [weak self] in
                    self?.currentValueSubject.send($0)
                }
            )

            var publisher: AnyPublisher<Bool, Never> { currentValueSubject.eraseToAnyPublisher() }

            private let currentValueSubject = CurrentValueSubject<Bool, Never>(false)

            init() {}

            func capture() {
                binding.wrappedValue = true
            }
        }
    }

    container {
        struct SnapshotButtonView: View {
            @Injected(\.snapshotTrigger) var snapshotTrigger

            var body: some View {
                Button {
                    snapshotTrigger.capture()
                } label: {
                    Label {
                        Text("Capture snapshot")
                    } icon: {
                        Image(systemName: "circle.inset.filled")
                    }
                }
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            func makeVideoParticipantsView(
                viewModel: CallViewModel,
                availableFrame: CGRect,
                onChangeTrackVisibility: @escaping @MainActor (CallParticipant, Bool) -> Void
            ) -> some View {
                DefaultViewFactory.shared.makeVideoParticipantsView(
                    viewModel: viewModel,
                    availableFrame: availableFrame,
                    onChangeTrackVisibility: onChangeTrackVisibility
                )
                .snapshot(trigger: snapshotTrigger) { [weak viewModel, weak self] in
                    guard
                        let resizedImage = self?.resize(image: $0, to: CGSize(width: 30, height: 30)),
                        let snapshotData = resizedImage.jpegData(compressionQuality: 0.8)
                    else { return }
                    Task {
                        do {
                            try await viewModel?.call?.sendCustomEvent([
                                "snapshot": .string(snapshotData.base64EncodedString())
                            ])
                            log.debug("Snapshot was sent successfully ✅")
                        } catch {
                            log.error("Snapshot failed to  send with error: \(error)")
                        }
                    }
                }
            }

            private func resize(
                image: UIImage,
                to targetSize: CGSize
            ) -> UIImage? {
                guard
                    image.size.width > targetSize.width || image.size.height > targetSize.height
                else {
                    return image
                }

                let widthRatio = targetSize.width / image.size.width
                let heightRatio = targetSize.height / image.size.height

                // Determine the scale factor that preserves aspect ratio
                let scaleFactor = min(widthRatio, heightRatio)

                let scaledWidth = image.size.width * scaleFactor
                let scaledHeight = image.size.height * scaleFactor
                let targetRect = CGRect(
                    x: (
                        targetSize.width - scaledWidth
                    ) / 2,
                    y: (targetSize.height - scaledHeight) / 2,
                    width: scaledWidth,
                    height: scaledHeight
                )

                // Create a new image context
                UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
                image.draw(in: targetRect)

                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                return newImage
            }
        }
    }

    container {
        @MainActor
        final class DemoSnapshotViewModel: ObservableObject {

            private let viewModel: CallViewModel
            private var snapshotEventsTask: Task<Void, Never>?

            @Published var toast: Toast?

            init(_ viewModel: CallViewModel) {
                self.viewModel = viewModel
                subscribeForSnapshotEvents()
            }

            private func subscribeForSnapshotEvents() {
                guard let call = viewModel.call else {
                    snapshotEventsTask?.cancel()
                    snapshotEventsTask = nil
                    return
                }

                snapshotEventsTask = Task {
                    for await event in call.subscribe(for: CustomVideoEvent.self) {
                        guard
                            let imageBase64Data = event.custom["snapshot"]?.stringValue,
                            let imageData = Data(base64Encoded: imageBase64Data),
                            let image = UIImage(data: imageData)
                        else {
                            return
                        }

                        toast = .init(
                            style: .custom(
                                baseStyle: .success,
                                icon: AnyView(
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(maxWidth: 30, maxHeight: 30)
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(Circle())
                                )
                            ),
                            message: "Snapshot captured!"
                        )
                    }
                }
            }
        }
    }

    container {
        @ObservedObject var snapshotViewModel = SnapshotViewModel()

        YourRootView()
            .toastView(toast: $snapshotViewModel.toast)
    }

    asyncContainer {
        final class Delegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {}
        let call: Call? = call

        let photoOutput: AVCapturePhotoOutput = .init()
        let videoOutput: AVCaptureVideoDataOutput = .init()

        do {
            if #available(iOS 16.0, *) {
                try await call?.addVideoOutput(videoOutput)
                /// Following Apple guidelines for videoOutputs from here:
                /// https://developer.apple.com/library/archive/technotes/tn2445/_index.html
                videoOutput.alwaysDiscardsLateVideoFrames = true
            } else {
                try await call?.addCapturePhotoOutput(photoOutput)
            }
        } catch {
            log.error("Failed to setup for localParticipant snapshot", error: error)
        }
    }

    container {
        final class Delegate: NSObject, AVCapturePhotoCaptureDelegate {}
        let photoOutput: AVCapturePhotoOutput = .init()

        func capturePhoto() {
            guard !photoOutput.connections.isEmpty else { return }
            photoOutput.capturePhoto(with: .init(), delegate: Delegate())
        }

        // MARK: - AVCapturePhotoCaptureDelegate

        func photoOutput(
            _ output: AVCapturePhotoOutput,
            didFinishProcessingPhoto photo: AVCapturePhoto,
            error: Error?
        ) {
            if let error {
                log.error("Failed to capture photo.", error: error)
            } else {
                if let data = photo.fileDataRepresentation() {
                    Task { await sendImageData(data) }
                }
            }
        }

        func sendImageData(_ data: Data) async {}
    }

    container {
        actor State {
            private(set) var isCapturingVideoFrame = false

            func setIsCapturingVideoFrame(_ value: Bool) {
                isCapturingVideoFrame = value
            }
        }

        let state: State = .init()
        let videoOutput: AVCaptureVideoDataOutput = .init()

        func captureVideoFrame() {
            guard !videoOutput.connections.isEmpty else { return }
            Task { await state.setIsCapturingVideoFrame(true) }
        }

        // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            Task {
                guard await state.isCapturingVideoFrame else { return }

                if let imageBuffer = sampleBuffer.imageBuffer {
                    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                    if let data = UIImage(ciImage: ciImage).jpegData(compressionQuality: 1) {
                        await sendImageData(data)
                    }
                }

                await state.setIsCapturingVideoFrame(false)
            }
        }

        func sendImageData(_ data: Data) async {
            defer { videoOutput.setSampleBufferDelegate(nil, queue: nil) }
        }
    }

    container {
        let call: Call? = call

        func sendImageData(_ data: Data) async {
            guard
                let snapshot = UIImage(data: data),
                let resizedImage = resize(image: snapshot, to: .init(width: 30, height: 30)),
                let snapshotData = resizedImage.jpegData(compressionQuality: 0.8)
            else {
                return
            }

            do {
                try await call?.sendCustomEvent([
                    "snapshot": .string(snapshotData.base64EncodedString())
                ])
            } catch {
                log.error("Failed to send image.", error: error)
            }
        }

        func resize(image: UIImage, to: CGSize) -> UIImage? { image }
    }
}
