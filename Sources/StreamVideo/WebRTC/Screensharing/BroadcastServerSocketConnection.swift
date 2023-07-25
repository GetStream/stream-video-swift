//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import Darwin

class BroadcastServerSocketConnection: NSObject {
    private let streamDelegate: StreamDelegate
    
    private let filePath: String
    private var socketHandle: Int32 = -1
    private var address: sockaddr_un?
    
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    private var listeningSource: DispatchSourceRead?
    private var networkQueue: DispatchQueue?
    private var shouldKeepRunning = false
    
    init?(filePath path: String, streamDelegate: StreamDelegate) {
        self.streamDelegate = streamDelegate
        filePath = path
        socketHandle = socket(AF_UNIX, SOCK_STREAM, 0)
        
        guard socketHandle >= 0 else {
            return nil
        }
    }
    
    func open() -> Bool {
        
        guard setupAddress() == true else {
            return false
        }
        
        guard bindSocket() == true else {
            return false
        }
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            return false
        }
        guard Darwin.listen(socketHandle, 10) >= 0 else {
            return false
        }
        
        let listeningSource = DispatchSource.makeReadSource(fileDescriptor: socketHandle)
        listeningSource.setEventHandler { [weak self] in
            guard let self else { return }
            let clientSocket = Darwin.accept(self.socketHandle, nil, nil)
            
            guard clientSocket >= 0 else {
                return
            }
            
            self.setupStreams(clientSocket: clientSocket)
            
            self.inputStream?.open()
            self.outputStream?.open()
        }
        
        self.listeningSource = listeningSource
        listeningSource.resume()
        return true
    }
    
    func close() {
        unscheduleStreams()
        
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        
        inputStream?.close()
        outputStream?.close()
        
        inputStream = nil
        outputStream = nil
        
        listeningSource?.cancel()
        Darwin.close(socketHandle)
    }
    
    func writeToStream(buffer: UnsafePointer<UInt8>, maxLength length: Int) -> Int {
        outputStream?.write(buffer, maxLength: length) ?? 0
    }
    
    private func setupAddress() -> Bool {
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        guard filePath.count < MemoryLayout.size(ofValue: addr.sun_path) else {
            return false
        }
        
        _ = filePath.withCString {
            unlink($0)
        }
        
        _ = withUnsafeMutablePointer(to: &addr.sun_path.0) { ptr in
            filePath.withCString {
                strncpy(ptr, $0, filePath.count)
            }
        }
        
        address = addr
        return true
    }
    
    private func bindSocket() -> Bool {
        guard var addr = address else {
            return false
        }
        
        let status = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(socketHandle, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        
        guard status == noErr else {
            return false
        }
        
        return true
    }
    
    private func setupStreams(clientSocket: Int32) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, clientSocket, &readStream, &writeStream)
        
        inputStream = readStream?.takeRetainedValue()
        inputStream?.delegate = self.streamDelegate
        inputStream?.setProperty(kCFBooleanTrue, forKey: Stream.PropertyKey(kCFStreamPropertyShouldCloseNativeSocket as String))
        
        outputStream = writeStream?.takeRetainedValue()
        outputStream?.setProperty(kCFBooleanTrue, forKey: Stream.PropertyKey(kCFStreamPropertyShouldCloseNativeSocket as String))
        
        scheduleStreams()
    }
    
    private func scheduleStreams() {
        shouldKeepRunning = true
        
        networkQueue = DispatchQueue.global(qos: .userInitiated)
        networkQueue?.async { [weak self] in
            self?.inputStream?.schedule(in: .current, forMode: .default)
            self?.outputStream?.schedule(in: .current, forMode: .default)
            
            var isRunning = false
            
            repeat {
                isRunning = self?.shouldKeepRunning ?? false && RunLoop.current.run(mode: .default, before: .distantFuture)
            } while (isRunning)
        }
    }
    
    private func unscheduleStreams() {
        networkQueue?.sync { [weak self] in
            self?.inputStream?.remove(from: .current, forMode: .common)
            self?.outputStream?.remove(from: .current, forMode: .common)
        }
        
        shouldKeepRunning = false
    }
}
