//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage
import CoreVideo
import Foundation
import StreamWebRTC

/// Accumulates framed broadcast bytes and produces a pixel buffer payload.
private class Message {
    #if compiler(>=6.2)
    static let imageContextVar: CIContext? = CIContext(options: nil)
    #else
    nonisolated(unsafe) static let imageContextVar: CIContext? = CIContext(options: nil)
    #endif

    var imageBuffer: CVImageBuffer?
    var onComplete: ((_ success: Bool, _ message: Message) -> Void)?
    var imageOrientation: CGImagePropertyOrientation = .up
    private var framedMessage: CFHTTPMessage?
    
    /// Creates a new message buffer.
    init() {}
    
    /// Appends bytes and returns how many bytes are still missing.
    func appendBytes(buffer: [UInt8], length: Int) -> Int {
        if framedMessage == nil {
            framedMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, false).takeRetainedValue()
        }
        
        guard let framedMessage = framedMessage else {
            return -1
        }
        
        CFHTTPMessageAppendBytes(framedMessage, buffer, length)
        if !CFHTTPMessageIsHeaderComplete(framedMessage) {
            return -1
        }
        
        guard let contentLengthStr = CFHTTPMessageCopyHeaderFieldValue(
            framedMessage,
            BroadcastConstants.contentLength as CFString
        )?.takeRetainedValue(),
            let body = CFHTTPMessageCopyBody(framedMessage)?.takeRetainedValue()
        else {
            return -1
        }
        
        let contentLength = Int(CFStringGetIntValue(contentLengthStr))
        let bodyLength = CFDataGetLength(body)
        
        let missingBytesCount = contentLength - bodyLength
        if missingBytesCount == 0 {
            let success = unwrapMessage(framedMessage)
            onComplete?(success, self)
            self.framedMessage = nil
        }
        
        return missingBytesCount
    }
    
    /// Returns a shared Core Image context for buffer rendering.
    private func imageContext() -> CIContext? {
        Message.imageContextVar
    }
    
    /// Extracts metadata and image data from a framed HTTP message.
    private func unwrapMessage(_ framedMessage: CFHTTPMessage) -> Bool {
        guard
            let widthStr = CFHTTPMessageCopyHeaderFieldValue(
                framedMessage,
                BroadcastConstants.bufferWidth as CFString
            )?.takeRetainedValue(),
            let heightStr = CFHTTPMessageCopyHeaderFieldValue(
                framedMessage,
                BroadcastConstants.bufferHeight as CFString
            )?.takeRetainedValue(),
            let imageOrientationStr = CFHTTPMessageCopyHeaderFieldValue(
                framedMessage,
                BroadcastConstants.bufferOrientation as CFString
            )?.takeRetainedValue(),
            let messageData = CFHTTPMessageCopyBody(framedMessage)?.takeRetainedValue()
        else {
            return false
        }
        
        let width = Int(CFStringGetIntValue(widthStr))
        let height = Int(CFStringGetIntValue(heightStr))
        imageOrientation = CGImagePropertyOrientation(
            rawValue: UInt32(CFStringGetIntValue(imageOrientationStr))
        ) ?? .up
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            nil,
            &imageBuffer
        )
        
        if status != kCVReturnSuccess {
            return false
        }
        
        copyImageData(messageData as Data, to: imageBuffer)
        
        return true
    }
    
    /// Renders image data into the provided pixel buffer.
    private func copyImageData(_ data: Data?, to pixelBuffer: CVPixelBuffer?) {
        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, [])
        }
        
        var image: CIImage?
        if let data = data {
            image = CIImage(data: data)
        }
        if let image = image, let pixelBuffer = pixelBuffer {
            imageContext()?.render(image, to: pixelBuffer)
        }
        
        if let pixelBuffer = pixelBuffer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        }
    }
}

/// Reads screen share data from a stream and emits decoded video frames.
final class BroadcastBufferReader: NSObject {
    private var readLength = 0
    
    private var connection: BroadcastBufferReaderConnection? {
        didSet {
            if connection != oldValue {
                oldValue?.close()
            }
        }
    }
    
    private var message: Message?
    /// Called when a decoded frame is ready for delivery to WebRTC.
    var onCapture: ((CVPixelBuffer, RTCVideoRotation) -> Void)?
    
    /// Creates a broadcast buffer reader.
    override init() {}
    
    /// Starts reading frames from the provided connection.
    func startCapturing(with connection: BroadcastBufferReaderConnection) {
        self.connection = connection
        message = nil
        
        if !connection.open() {
            stopCapturing()
        }
    }
    
    /// Stops reading frames and closes the connection.
    func stopCapturing() {
        connection?.close()
        connection = nil
    }
    
    // MARK: private
    
    /// Reads available bytes from the stream and assembles frames.
    func readBytes(from stream: InputStream) {
        guard stream.hasBytesAvailable else { return }
        
        if message == nil {
            message = Message()
            readLength = BroadcastConstants.bufferMaxLength

            message?.onComplete = { [weak self] success, message in
                if success {
                    self?.didCaptureVideoFrame(message.imageBuffer, with: message.imageOrientation)
                }
                
                self?.message = nil
            }
        }
        
        guard let msg = message else { return }
        
        var buffer = [UInt8](repeating: 0, count: readLength)
        let numberOfBytesRead = stream.read(&buffer, maxLength: readLength)
        
        if numberOfBytesRead < 0 {
            return
        }
        
        readLength = msg.appendBytes(buffer: buffer, length: numberOfBytesRead)
        if readLength == -1 || readLength > BroadcastConstants.bufferMaxLength {
            readLength = BroadcastConstants.bufferMaxLength
        }
    }
    
    /// Converts the message orientation into WebRTC rotation and emits it.
    func didCaptureVideoFrame(
        _ pixelBuffer: CVPixelBuffer?,
        with orientation: CGImagePropertyOrientation
    ) {
        guard let pixelBuffer = pixelBuffer else {
            return
        }
        
        var rotation: RTCVideoRotation
        switch orientation {
        case .left:
            rotation = ._90
        case .down:
            rotation = ._180
        case .right:
            rotation = ._270
        default:
            rotation = ._0
        }
        
        onCapture?(pixelBuffer, rotation)
    }
}

extension BroadcastBufferReader: StreamDelegate {
    /// Handles stream events and drives frame assembly.
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            log.debug("server stream open completed")
        case .hasBytesAvailable:
            readBytes(from: aStream as! InputStream)
        case .endEncountered:
            stopCapturing()
            log.debug("stopping capture")
        case .errorOccurred:
            log.debug("server stream error encountered: \(aStream.streamError?.localizedDescription ?? "")")
        default:
            break
        }
    }
}
