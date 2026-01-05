//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

class BroadcastBufferConnection: NSObject, @unchecked Sendable {
    
    var inputStream: InputStream?
    var outputStream: OutputStream?
    
    var streamQueue: DispatchQueue?
    var shouldKeepRunning = false
    
    func writeToStream(buffer: UnsafePointer<UInt8>, maxLength length: Int) -> Int {
        outputStream?.write(buffer, maxLength: length) ?? 0
    }
    
    func close() {
        unscheduleStreams()
        closeStreams()
    }
    
    func openStreams() {
        inputStream?.open()
        outputStream?.open()
    }
    
    func closeStreams() {
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        
        inputStream?.close()
        outputStream?.close()
        
        inputStream = nil
        outputStream = nil
    }
    
    func setupStreams(clientSocket: Int32, delegate: StreamDelegate, handleOutput: Bool) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, clientSocket, &readStream, &writeStream)
        
        inputStream = readStream?.takeRetainedValue()
        inputStream?.delegate = delegate
        inputStream?.setProperty(kCFBooleanTrue, forKey: Stream.PropertyKey(kCFStreamPropertyShouldCloseNativeSocket as String))
        
        outputStream = writeStream?.takeRetainedValue()
        if handleOutput {
            outputStream?.delegate = delegate
        }
        outputStream?.setProperty(kCFBooleanTrue, forKey: Stream.PropertyKey(kCFStreamPropertyShouldCloseNativeSocket as String))
        
        scheduleStreams()
    }
    
    // MARK: - private
    
    private func scheduleStreams() {
        shouldKeepRunning = true
        
        streamQueue = DispatchQueue.global(qos: .userInteractive)
        streamQueue?.async { [weak self] in
            self?.inputStream?.schedule(in: .current, forMode: .common)
            self?.outputStream?.schedule(in: .current, forMode: .common)
            RunLoop.current.run()
            
            var isRunning = false
            
            repeat {
                isRunning = self?.shouldKeepRunning ?? false
                    && RunLoop.current.run(mode: .default, before: .distantFuture)
            } while (isRunning)
        }
    }
    
    private func unscheduleStreams() {
        streamQueue?.sync { [weak self] in
            self?.inputStream?.remove(from: .current, forMode: .common)
            self?.outputStream?.remove(from: .current, forMode: .common)
        }
        
        shouldKeepRunning = false
    }
}
