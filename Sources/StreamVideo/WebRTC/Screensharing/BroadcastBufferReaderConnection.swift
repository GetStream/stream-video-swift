//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Darwin
import Foundation

final class BroadcastBufferReaderConnection: BroadcastBufferConnection, @unchecked Sendable {
    private let streamDelegate: StreamDelegate
    
    private let filePath: String
    private var socketHandle: Int32 = -1
    private var address: sockaddr_un?
    
    private var listeningSource: DispatchSourceRead?
    
    init?(filePath path: String, streamDelegate: StreamDelegate) {
        self.streamDelegate = streamDelegate
        filePath = path
        socketHandle = socket(AF_UNIX, SOCK_STREAM, 0)
        
        guard socketHandle >= 0 else {
            return nil
        }
    }
    
    func open() -> Bool {
        guard setupAddress(),
              bindSocket(),
              FileManager.default.fileExists(atPath: filePath),
              Darwin.listen(socketHandle, 10) >= 0
        else {
            return false
        }
        
        let listeningSource = DispatchSource.makeReadSource(fileDescriptor: socketHandle)
        listeningSource.setEventHandler { [weak self] in
            guard let self else { return }
            let clientSocket = Darwin.accept(self.socketHandle, nil, nil)
            
            guard clientSocket >= 0 else {
                return
            }
            
            self.setupStreams(
                clientSocket: clientSocket,
                delegate: self.streamDelegate,
                handleOutput: false
            )
            self.openStreams()
        }
        
        self.listeningSource = listeningSource
        listeningSource.resume()
        return true
    }
    
    override func close() {
        super.close()
        listeningSource?.cancel()
        Darwin.close(socketHandle)
    }
    
    // MARK: - private
    
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
}
