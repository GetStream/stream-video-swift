//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamVideo
import SwiftUI

public class PreJoiningViewModel: ObservableObject, @unchecked Sendable {
    private let camera: Any
 
    @Published public var viewfinderImage: Image?
    @Published public var connectionQuality = ConnectionQuality.unknown
    
    public var latencyURL: String? {
        didSet {
            if latencyURL != nil {
                setupLatencyChecks()
            }
        }
    }
    
    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        let urlSession = URLSession(configuration: config)
        return urlSession
    }()
    
    private var timer: Timer?
    private let latencyCheckInterval: TimeInterval = 5.0
    
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
        let imageStream = (camera as? Camera)?.previewStream
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
                await(camera as? Camera)?.start()
                if front {
                    (camera as? Camera)?.switchCaptureDevice()
                }
            }
        }
    }
    
    private func execute(request: URLRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let task = urlSession.dataTask(with: request) { data, _, error in
                if let error = error {
                    log.debug("Error executing request \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: data ?? Data())
            }
            task.resume()
        }
    }
    
    private func setupLatencyChecks() {
        guard latencyURL != nil else { return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: latencyCheckInterval,
            repeats: true,
            block: { [weak self] _ in
                self?.performLatencyCheck()
            }
        )
    }
    
    private func performLatencyCheck() {
        guard let latencyURL = latencyURL, let url = URL(string: latencyURL) else {
            return
        }
        let startDate = Date()
        Task {
            do {
                var urlRequest = URLRequest(url: url)
                urlRequest.timeoutInterval = 1.0
                _ = try await self.execute(request: urlRequest)
                let diff = Double(Date().timeIntervalSince(startDate))
                await MainActor.run {
                    if diff < 0.25 {
                        self.connectionQuality = .excellent
                    } else if diff < 0.5 {
                        self.connectionQuality = .good
                    } else {
                        self.connectionQuality = .poor
                    }
                }
            } catch {
                await MainActor.run {
                    self.connectionQuality = .poor
                }
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
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
