//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A thread-safe storage class for managing PeerConnectionFactory instances.
final class PeerConnectionFactoryStorage: @unchecked Sendable {
    /// Shared singleton instance of PeerConnectionFactoryStorage.
    static let shared = PeerConnectionFactoryStorage()
    
    /// Dictionary to store PeerConnectionFactory instances, keyed by module address.
    private var storage: [String: PeerConnectionFactory] = [:]
    
    /// Queue to ensure thread-safe access to the storage.
    private let queue = UnfairQueue()
    
    /// Stores a PeerConnectionFactory instance for a given RTCAudioProcessingModule.
    /// - Parameters:
    ///   - factory: The PeerConnectionFactory to store.
    ///   - module: The RTCAudioProcessingModule associated with the factory.
    func store(
        _ factory: PeerConnectionFactory,
        for module: RTCAudioProcessingModule
    ) {
        queue.sync {
            storage[key(for: module)] = factory
        }
    }
    
    /// Retrieves a PeerConnectionFactory instance for a given RTCAudioProcessingModule.
    /// - Parameter module: The RTCAudioProcessingModule to lookup.
    /// - Returns: The associated PeerConnectionFactory, if found.
    func factory(for module: RTCAudioProcessingModule) -> PeerConnectionFactory? {
        queue.sync {
            storage[key(for: module)]
        }
    }
    
    /// Removes a PeerConnectionFactory instance for a given RTCAudioProcessingModule.
    /// If the storage becomes empty after removal, it cleans up SSL.
    /// - Parameter module: The RTCAudioProcessingModule to remove.
    func remove(for module: RTCAudioProcessingModule) {
        queue.sync {
            storage[key(for: module)] = nil
            if storage.isEmpty {
                /// SSL cleanUp should only occur when no factory is active. During tests where
                /// factories are being created on demand this is causing failures. The storage ensures
                /// that only when there is no other factory the SSL will be cleaned up.
                RTCCleanupSSL()
            }
        }
    }
    
    private func key(for object: AnyObject) -> String {
        "\(Unmanaged.passUnretained(object).toOpaque())"
    }
}
