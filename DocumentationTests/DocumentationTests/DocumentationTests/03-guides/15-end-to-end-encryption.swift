//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import CryptoKit
import Foundation
import StreamVideo

@MainActor
private func content(
    encryption: EncryptionManager,
    sharedKey: Data,
    aliceKey: Data,
    nextSharedKey: Data
) {
    asyncContainer {
        let call = streamVideo.call(callType: "e2ee", callId: "my-call-id")
        let encryption = try EncryptionManager(userId: streamVideo.user.id)

        try encryption.setSharedKey(0, rawKey: sharedKey)
        try await call.setE2EEManager(encryption)
        try await call.join(create: true)
    }

    asyncContainer {
        try await call.create(
            encryption: EncryptionSettingsRequest(mode: .autoOn)
        )
        try await call.join()
    }

    container {
        let encryption = try EncryptionManager(
            userId: streamVideo.user.id,
            algorithm: .aes256Gcm
        )
        _ = encryption
    }

    container {
        try encryption.setSharedKey(0, rawKey: sharedKey)
    }

    container {
        let key = SymmetricKey(size: .bits128)
        let sharedKey = key.withUnsafeBytes { Data($0) }
        _ = sharedKey
    }

    container {
        try encryption.setKey("alice", keyIndex: 0, rawKey: aliceKey)
    }

    container {
        try encryption.setSharedKey(1, rawKey: nextSharedKey)
    }

    container {
        try encryption.removeSharedKey(0)
        try encryption.removeKey("alice", keyIndex: 0)
        try encryption.removeAllKeys("alice")
    }

    container {
        let encryptionSubscription = encryption.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch event.name {
                case "e2ee.missing_key":
                    print("Missing key for user: \(event.userId)")
                case "e2ee.decryption_failed", "e2ee.decryption_stalled":
                    print("Unable to decrypt media for user: \(event.userId)")
                case "e2ee.decryption_resumed":
                    print("Decryption resumed for user: \(event.userId)")
                default:
                    break
                }
            }
        _ = encryptionSubscription
    }

    container {
        _ = EncryptionManager.isSupported
    }

    asyncContainer {
        try await call.setE2EEManager(nil)
    }

    container {
        call.leave()
        encryption.dispose()
    }
}
