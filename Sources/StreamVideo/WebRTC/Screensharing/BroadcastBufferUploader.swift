//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import ReplayKit
import StreamWebRTC

actor BroadcastBufferUploader {
    
    private static let imageContext = CIContext(options: nil)
    
    private var isReady = false
    private var connection: BroadcastBufferUploadConnection

    private var dataToSend: Data?
    private var byteIndex = 0
    private let compressionQuality: Float = 0.7
    private let disposableBag = DisposableBag()

    private let executor = DispatchQueueExecutor()
    nonisolated var unownedExecutor: UnownedSerialExecutor { .init(ordinary: executor) }

    init(connection: BroadcastBufferUploadConnection) {
        self.connection = connection
        Task(disposableBag: disposableBag) { [weak self] in
            await self?.setupConnection()
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
        connection.onOpen = { [weak self] in
            guard let self else { return }
            Task(disposableBag: disposableBag) { [weak self] in
                await self?.update(isReady: true)
            }
        }
        connection.hasSpaceAvailable = { [weak self] in
            guard let self else { return }
            Task(disposableBag: disposableBag) { [weak self] in
                guard let self else { return }
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
        var length = bytesLeft > BroadcastConstants.bufferMaxLength ? BroadcastConstants.bufferMaxLength : bytesLeft
        
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
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let orientation = CMGetAttachment(
            buffer,
            key: RPVideoSampleOrientationKey as CFString,
            attachmentModeOut: nil
        )?.uintValue ?? 0
        
        let bufferData = self.jpegData(from: imageBuffer)
        
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
    
    func jpegData(from buffer: CVPixelBuffer) -> Data? {
        let image = CIImage(cvPixelBuffer: buffer)
        
        guard let colorSpace = image.colorSpace else {
            return nil
        }
        
        let options: [CIImageRepresentationOption: Float] = [
            kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: compressionQuality
        ]
        
        return BroadcastBufferUploader.imageContext.jpegRepresentation(of: image, colorSpace: colorSpace, options: options)
    }
    
    private func makeHttpResponse(
        messageData: Data,
        width: Int,
        height: Int,
        orientation: UInt
    ) -> CFHTTPMessage {
        let httpResponse = CFHTTPMessageCreateResponse(nil, 200, nil, kCFHTTPVersion1_1).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(
            httpResponse,
            BroadcastConstants.contentLength as CFString,
            String(messageData.count) as CFString
        )
        CFHTTPMessageSetHeaderFieldValue(
            httpResponse,
            BroadcastConstants.bufferWidth as CFString,
            String(width) as CFString
        )
        CFHTTPMessageSetHeaderFieldValue(
            httpResponse,
            BroadcastConstants.bufferHeight as CFString,
            String(height) as CFString
        )
        CFHTTPMessageSetHeaderFieldValue(
            httpResponse,
            BroadcastConstants.bufferOrientation as CFString,
            String(orientation) as CFString
        )
        CFHTTPMessageSetBody(httpResponse, messageData as CFData)
        
        return httpResponse
    }
}
