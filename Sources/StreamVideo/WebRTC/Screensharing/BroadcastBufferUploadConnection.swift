//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

class BroadcastBufferUploadConnection: BroadcastBufferConnection, @unchecked Sendable {
    var onOpen: (() -> Void)?
    var onClose: ((Error?) -> Void)?
    var hasSpaceAvailable: (() -> Void)?
    
    private let filePath: String
    private var socketHandle: Int32 = -1
    private var address: sockaddr_un?
        
    init?(filePath path: String) {
        filePath = path
        socketHandle = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        
        guard socketHandle != -1 else {
            return nil
        }
    }
    
    func open() -> Bool {
        guard FileManager.default.fileExists(atPath: filePath),
              setupAddress(),
              connectSocket() else {
            return false
        }
        
        setupStreams(
            clientSocket: socketHandle,
            delegate: self,
            handleOutput: true
        )
        openStreams()
        
        return true
    }
    
    // MARK: - private
    
    private func setupAddress() -> Bool {
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        guard filePath.count < MemoryLayout.size(ofValue: addr.sun_path) else {
            return false
        }
        
        _ = withUnsafeMutablePointer(to: &addr.sun_path.0) { ptr in
            filePath.withCString {
                strncpy(ptr, $0, filePath.count)
            }
        }
        
        address = addr
        return true
    }
    
    private func connectSocket() -> Bool {
        guard var addr = address else {
            return false
        }
        
        let status = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(socketHandle, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        
        return status == noErr
    }
}

extension BroadcastBufferUploadConnection: StreamDelegate {
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            if aStream == outputStream {
                onOpen?()
            }
        case .hasBytesAvailable:
            if aStream == inputStream {
                var buffer: UInt8 = 0
                let numberOfBytesRead = inputStream?.read(&buffer, maxLength: 1)
                if numberOfBytesRead == 0 && aStream.streamStatus == .atEnd {
                    close()
                    onClose?(nil)
                }
            }
        case .hasSpaceAvailable:
            if aStream == outputStream {
                hasSpaceAvailable?()
            }
        case .errorOccurred:
            close()
            onClose?(aStream.streamError)
        default:
            break
        }
    }
}
