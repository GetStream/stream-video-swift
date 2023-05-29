//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamVideo
import SwiftUI

@MainActor
public class LobbyViewModel: ObservableObject, @unchecked Sendable {
    private let camera: Any
 
    @Published public var viewfinderImage: Image?
    
    public init() {
        if #available(iOS 14, *) {
            camera = Camera()
            Task {
                await handleCameraPreviews()
            }
        } else {
            camera = NSObject()
        }
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
            Task {
                await (camera as? Camera)?.start()
                if front {
                    (camera as? Camera)?.switchCaptureDevice()
                }
            }
        }
    }
    
    func stopCamera() {
        if #available(iOS 14, *) {
            (camera as? Camera)?.stop()
        }
    }
}

extension Image: @unchecked Sendable {}

private extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}
