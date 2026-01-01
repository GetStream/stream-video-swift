//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreImage
import CoreVideo
import Foundation
import StreamWebRTC

private class Message {
    static let imageContextVar: CIContext? = {
        var imageContext = CIContext(options: nil)
        return imageContext
    }()
    
    var imageBuffer: CVImageBuffer?
    var onComplete: ((_ success: Bool, _ message: Message) -> Void)?
    var imageOrientation: CGImagePropertyOrientation = .up
    private var framedMessage: CFHTTPMessage?
    
    init() {}
    
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
    
    private func imageContext() -> CIContext? {
        Message.imageContextVar
    }
    
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
    var onCapture: ((CVPixelBuffer, RTCVideoRotation) -> Void)?
    
    override init() {}
    
    func startCapturing(with connection: BroadcastBufferReaderConnection) {
        self.connection = connection
        message = nil
        
        if !connection.open() {
            stopCapturing()
        }
    }
    
    func stopCapturing() {
        connection?.close()
        connection = nil
    }
    
    // MARK: private
    
    func readBytes(from stream: InputStream) {
        guard stream.hasBytesAvailable else { return }
        
        if message == nil {
            message = Message()
            readLength = BroadcastConstants.bufferMaxLength
            
            weak var weakSelf = self
            message?.onComplete = { success, message in
                if success {
                    weakSelf?.didCaptureVideoFrame(message.imageBuffer, with: message.imageOrientation)
                }
                
                weakSelf?.message = nil
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
