//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import UIKit
import Intents

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        let interaction = userActivity.interaction
        if let callIntent = interaction?.intent as? INStartCallIntent {
            
            let contact = callIntent.contacts?.first
            
            let contactHandle = contact?.personHandle
            
            if let phoneNumber = contactHandle?.value {
                print(phoneNumber)
                // Your Call Logic
            }
        }
    }
    
}
