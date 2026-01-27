//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        let response = try await call.sendCustomEvent(["type": .string("draw"), "x": .number(10), "y": .number(20)])
    }
    
    asyncContainer {
        func sendImageData(_ data: Data) async {
            guard
                let snapshot = UIImage(data: data),
                let resizedImage = resize(image: snapshot, to: .init(width: 30, height: 30)),
                let snapshotData = resizedImage.jpegData(compressionQuality: 0.8)
            else {
                return
            }

            do {
                try await call.sendCustomEvent([
                    "snapshot": .string(snapshotData.base64EncodedString())
                ])
            } catch {
                log.error("Failed to send image.", error: error)
            }
        }

        func resize(
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
                x: (targetSize.width - scaledWidth) / 2,
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
    
    asyncContainer {
        for await event in call.subscribe(for: CustomVideoEvent.self) {
            // read custom data
            let customData = event.custom
            // perform actions with the custom data.
        }
    }

    container {
        @MainActor
        func observeCallEvents(call: Call) {
            Task {
                for await event in call.subscribe() {
                    switch event {
                    case .typeCallSessionParticipantJoinedEvent(let e):
                        print("\(e.participant.user.name ?? "Someone") joined")

                    case .typeCallSessionParticipantLeftEvent(let e):
                        print("\(e.participant.user.name ?? "Someone") left")

                    case .typeCallRecordingStartedEvent:
                        print("Recording started")

                    case .typeCallRecordingStoppedEvent:
                        print("Recording stopped")

                    case .typeCallReactionEvent(let e):
                        print("Reaction: \(e.reaction)")

                    case .typeCustomVideoEvent(let e):
                        print("Custom event: \(e.custom)")

                    default:
                        break
                    }
                }
            }
        }
    }

    container {
        @MainActor
        class CallObserver {
            private var eventTask: Task<Void, Never>?

            func startObserving(call: Call) {
                eventTask = Task {
                    for await event in call.subscribe() {
                        // Handle events
                        _ = event
                    }
                }
            }

            func stopObserving() {
                eventTask?.cancel()
                eventTask = nil
            }
        }
    }
}
