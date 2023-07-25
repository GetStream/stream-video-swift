//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC
import ReplayKit

private enum Constants {
    static let bufferMaxLength = 10240
}

actor SampleUploader {
    
    private static var imageContext = CIContext(options: nil)
    
    private var isReady = false
    private var connection: BroadcastUploadSocketConnection
    
    private var dataToSend: Data?
    private var byteIndex = 0
    private let compressionQuality: Float = 0.6
        
    init(connection: BroadcastUploadSocketConnection) {
        self.connection = connection
        Task {
            await setupConnection()
        }
    }
    
    @discardableResult func send(sample buffer: CMSampleBuffer) -> Bool {
        guard isReady else {
            return false
        }
        
        isReady = false
        
        dataToSend = prepare(sample: buffer)
        byteIndex = 0
        self.sendDataChunk()
        
        return true
    }
    
    func update(isReady: Bool) {
        self.isReady = isReady
    }
    
    func setupConnection() {
        connection.didOpen = { [weak self] in
            guard let self else { return }
            Task {
                await self.update(isReady: true)
            }
        }
        connection.streamHasSpaceAvailable = { [weak self] in
            guard let self else { return }
            Task {
                let success = await self.sendDataChunk()
                await self.update(isReady: !success)
            }
        }
    }
    
    @discardableResult func sendDataChunk() -> Bool {
        guard let dataToSend = dataToSend else {
            return false
        }
        
        var bytesLeft = dataToSend.count - byteIndex
        var length = bytesLeft > Constants.bufferMaxLength ? Constants.bufferMaxLength : bytesLeft
        
        length = dataToSend[byteIndex..<(byteIndex + length)].withUnsafeBytes {
            guard let ptr = $0.bindMemory(to: UInt8.self).baseAddress else {
                return 0
            }
            
            return connection.writeToStream(buffer: ptr, maxLength: length)
        }
        
        if length > 0 {
            byteIndex += length
            bytesLeft -= length
            
            if bytesLeft == 0 {
                self.dataToSend = nil
                byteIndex = 0
            }
        }
        
        return true
    }
    
    func prepare(sample buffer: CMSampleBuffer) -> Data? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        
        let scaleFactor = 1.0
        let width = CVPixelBufferGetWidth(imageBuffer)/Int(scaleFactor)
        let height = CVPixelBufferGetHeight(imageBuffer)/Int(scaleFactor)
        
        let orientation = CMGetAttachment(
            buffer,
            key: RPVideoSampleOrientationKey as CFString,
            attachmentModeOut: nil
        )?.uintValue ?? 0
        
        let scaleTransform = CGAffineTransform(scaleX: CGFloat(1.0/scaleFactor), y: CGFloat(1.0/scaleFactor))
        let bufferData = self.jpegData(from: imageBuffer, scale: scaleTransform)
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        
        guard let messageData = bufferData else {
            return nil
        }
        
        let httpResponse = makeHttpResponse(
            messageData: messageData,
            width: width,
            height: height,
            orientation: orientation
        )
        
        let serializedMessage = CFHTTPMessageCopySerializedMessage(httpResponse)?.takeRetainedValue() as Data?
        
        return serializedMessage
    }
    
    func jpegData(from buffer: CVPixelBuffer, scale scaleTransform: CGAffineTransform) -> Data? {
        let image = CIImage(cvPixelBuffer: buffer).transformed(by: scaleTransform)
        
        guard let colorSpace = image.colorSpace else {
            return nil
        }
        
        let options: [CIImageRepresentationOption: Float] = [
            kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: compressionQuality
        ]
        
        return SampleUploader.imageContext.jpegRepresentation(of: image, colorSpace: colorSpace, options: options)
    }
    
    private func makeHttpResponse(
        messageData: Data,
        width: Int,
        height: Int,
        orientation: UInt
    ) -> CFHTTPMessage {
        let httpResponse = CFHTTPMessageCreateResponse(nil, 200, nil, kCFHTTPVersion1_1).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(httpResponse, "Content-Length" as CFString, String(messageData.count) as CFString)
        CFHTTPMessageSetHeaderFieldValue(httpResponse, "Buffer-Width" as CFString, String(width) as CFString)
        CFHTTPMessageSetHeaderFieldValue(httpResponse, "Buffer-Height" as CFString, String(height) as CFString)
        CFHTTPMessageSetHeaderFieldValue(httpResponse, "Buffer-Orientation" as CFString, String(orientation) as CFString)
        
        CFHTTPMessageSetBody(httpResponse, messageData as CFData)
        return httpResponse
    }
}
