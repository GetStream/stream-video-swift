//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension String {
    
    var preferredRedCodec: String {
        let parts = self.components(separatedBy: "\r\n")
        var redId: String = ""
        var opusId: String = ""
        for part in parts {
            if part.contains(" opus/") && opusId.isEmpty {
                opusId = extractId(from: part)
            }
            if part.contains(" red/48000/2") && redId.isEmpty {
                redId = extractId(from: part)
            }
            if !opusId.isEmpty && !redId.isEmpty {
                break
            }
        }
        
        if !redId.isEmpty && !opusId.isEmpty {
            let redOpusPair = "\(redId) \(opusId)"
            let opusRedPair = "\(opusId) \(redId)"
            let updatedResult = self.replacingOccurrences(
                of: opusRedPair,
                with: redOpusPair
            )
            
            return updatedResult
        } else {
            return self
        }
    }
    
    private func extractId(from part: String) -> String {
        guard let idPart = part.components(separatedBy: " ").first else {
            return ""
        }
        let components = idPart.components(separatedBy: ":")
        guard components.count > 1 else { return "" }
        return components[1]
    }
    
}
