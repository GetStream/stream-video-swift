//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage
import Foundation
import StreamVideo
import StreamVideoSwiftUI
import StreamWebRTC
import SwiftUI
import Vision

@MainActor
private func content() {
    container {
        let sepia: VideoFilter = {
            let sepia = VideoFilter(id: "sepia", name: "Sepia") { input in
                let sepiaFilter = CIFilter(name: "CISepiaTone")
                sepiaFilter?.setValue(input.originalImage, forKey: kCIInputImageKey)
                return sepiaFilter?.outputImage ?? input.originalImage
            }
            return sepia
        }()
    }

    container {

        class FiltersService: ObservableObject {
            @Published var filtersShown = false
            @Published var selectedFilter: VideoFilter?

            static let supportedFilters = [sepia]
        }

        let streamVideo = StreamVideo(
            apiKey: apiKey,
            user: userCredentials.user,
            token: token,
            // highlight-start
            videoConfig: VideoConfig(
                videoFilters: FiltersService.supportedFilters
            ),
            // highlight-end
            tokenProvider: { _ in
                // Unrelated code skipped. Check repository for complete code:
                // https://github.com/GetStream/stream-video-ios-examples/blob/main/VideoWithChat/VideoWithChat/StreamWrapper.swift
            }
        )
        connectUser()

        func connectUser() {
            Task {
                try await streamVideo.connect()
            }
        }
    }

    container {
        class VideoViewFactory: ViewFactory {

            func makeOutgoingCallView(viewModel: CallViewModel) -> some View {
                CustomOutgoingCallView(viewModel: viewModel)
            }
        }
    }

    container {
        struct ChatCallControls: View {
            var body: some View {
                VStack {
                    HStack {
                        /* Skip unrelated code */
                        // highlight-next-line
                        // 1. Button to toggle filters view
                        Button {
                            withAnimation {
                                filtersService.filtersShown.toggle()
                            }
                        } label: {
                            CallIconView(
                                icon: Image(systemName: "camera.filters"),
                                size: size,
                                iconStyle: filtersService.filtersShown ? .primary : .transparent
                            )
                        }
                        /* Skip unrelated code */
                    }

                    if filtersService.filtersShown {
                        HStack(spacing: 16) {
                            // highlight-next-line
                            // 2. Show a button for each filter
                            ForEach(FiltersService.supportedFilters, id: \.id) { filter in
                                Button {
                                    withAnimation {
                                        // highlight-next-line
                                        // 3. Select or de-select filter on tap
                                        if filtersService.selectedFilter?.id == filter.id {
                                            filtersService.selectedFilter = nil
                                        } else {
                                            filtersService.selectedFilter = filter
                                        }
                                        viewModel.setVideoFilter(filtersService.selectedFilter)
                                    }
                                } label: {
                                    Text(filter.name)
                                        .background(filtersService.selectedFilter?.id == filter.id ? Color.blue : Color.gray)
                                    /* more modifiers */
                                }
                            }
                        }
                    }
                }
                /* more modifiers */
            }
        }
    }

    container {
        func detectFaces(image: CIImage) async throws -> CGRect {
            return try await withCheckedThrowingContinuation { continuation in
                let detectFaceRequest = VNDetectFaceRectanglesRequest { (request, _) in
                    if let result = request.results?.first as? VNFaceObservation {
                        continuation.resume(returning: result.boundingBox)
                    } else {
                        continuation.resume(throwing: ClientError.Unknown())
                    }
                }
                let vnImage = VNImageRequestHandler(ciImage: image, orientation: .downMirrored)
                try? vnImage.perform([detectFaceRequest])
            }
        }

        func convert(ciImage: CIImage) -> UIImage {
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!
            let image = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
            return image
        }

        @MainActor
        func drawImageIn(_ image: UIImage, size: CGSize, _ logo: UIImage, inRect: CGRect) -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: CGPoint.zero, size: size))
                logo.draw(in: inRect)
            }
        }

        let stream: VideoFilter = {
            let stream = VideoFilter(id: "stream", name: "Stream") { input in
                // highlight-next-line
                // 1. detect, where the face is located (if there's any)
                guard let faceRect = try? await detectFaces(image: input.originalImage) else { return input.originalImage }
                let converted = convert(ciImage: input.originalImage)
                let bounds = input.originalImage.extent
                let convertedRect = CGRect(
                    x: faceRect.minX * bounds.width - 80,
                    y: faceRect.minY * bounds.height,
                    width: faceRect.width * bounds.width,
                    height: faceRect.height * bounds.height
                )
                // highlight-next-line
                // 2. Overlay the rectangle onto the original image
                let overlayed = drawImageIn(converted, size: bounds.size, streamLogo, inRect: convertedRect)

                // highlight-next-line
                // 3. convert the created image to a CIImage
                let result = CIImage(cgImage: overlayed.cgImage!)
                return result
            }
            return stream
        }()
    }

    viewContainer {
        Button {
            call.setVideoFilter(.blurredBackground)
        } label: {
            Text("Apply blur background filter")
        }

        Button {
            call.setVideoFilter(nil)
        } label: {
            Text("Remove background filter")
        }
    }

    viewContainer {
        Button {
            call.setVideoFilter(.imageBackground(CIImage(image: uiImage)!, id: "my-awesome-image-background-filter"))
        } label: {
            Text("Apply image background filter")
        }

        Button {
            call.setVideoFilter(nil)
        } label: {
            Text("Remove background filter")
        }
    }

    container {
        final class RobotVoiceFilter: AudioFilter {

            let pitchShift: Float

            init(pitchShift: Float) {
                self.pitchShift = pitchShift
            }

            // MARK: - AudioFilter

            var id: String { "robot-\(pitchShift)" }

            func applyEffect(to buffer: inout RTCAudioBuffer) {
                let frameSize = 256
                let hopSize = 128
                let scaleFactor = Float(frameSize) / Float(hopSize)

                let numFrames = (buffer.frames - frameSize) / hopSize

                for channel in 0..<buffer.channels {
                    let channelBuffer = buffer.rawBuffer(forChannel: channel)

                    for i in 0..<numFrames {
                        let inputOffset = i * hopSize
                        let outputOffset = Int(Float(i) * scaleFactor) * hopSize

                        var outputFrame = [Float](repeating: 0.0, count: frameSize)

                        // Apply pitch shift
                        for j in 0..<frameSize {
                            let shiftedIndex = Int(Float(j) * pitchShift)
                            let originalIndex = inputOffset + j
                            if shiftedIndex >= 0 && shiftedIndex < frameSize && originalIndex >= 0 && originalIndex < buffer
                                .frames {
                                outputFrame[shiftedIndex] = channelBuffer[originalIndex]
                            }
                        }

                        // Copy back to the input buffer
                        for j in 0..<frameSize {
                            let outputIndex = outputOffset + j
                            if outputIndex >= 0 && outputIndex < buffer.frames {
                                channelBuffer[outputIndex] = outputFrame[j]
                            }
                        }
                    }
                }
            }
        }

        container {
            // Get a call object
            let call = streamVideo.call(callType: "default", callId: UUID().uuidString)

            // Create our audio filter
            let filter = RobotVoiceFilter(pitchShift: 0.8)

            // Apply the audio filter on the call. To deactivate the filter we can simply pass `nil`.
            call.setAudioFilter(filter)
        }
    }
}
