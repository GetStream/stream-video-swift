//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum KrispModel: String {
    case c5ns20949d = "c5.n.s.20949d"
    case c5swc9ac8f = "c5.s.w.c9ac8f"
    case c6fsced125 = "c6.f.s.ced125"
    case vad = "VAD_model"

    func path(in bundle: Bundle = .main, extension ext: String = "kw") -> String {
        bundle.path(forResource: rawValue, ofType: ext)!
    }
}
