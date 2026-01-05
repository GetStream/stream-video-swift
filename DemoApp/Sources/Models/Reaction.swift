//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct Reaction: Identifiable, Codable, Equatable {

    enum ID: String, Codable {
        case fireworks = ":fireworks:"
        case raiseHand = ":raise-hand:"
        case lowerHand = ":lower-hand:"
        case like = ":like:"
        case dislike = ":dislike:"
        case hello = ":hello:"
        case smile = ":smile:"
        case heart = ":heart:"
    }

    var id: ID
    var duration: Double?
    var userSpecific: Bool = false
    var iconName: String
    var title: String

    static let fireworks = Reaction(id: .fireworks, iconName: "party.popper.fill", title: "Fireworks")
    static let raiseHand = Reaction(id: .raiseHand, userSpecific: true, iconName: "hand.raised.fill", title: "Raise hand")
    static let lowerHand = Reaction(id: .lowerHand, userSpecific: true, iconName: "hand.raised.slash.fill", title: "Lower hand")
    static let like = Reaction(id: .like, duration: 5, userSpecific: true, iconName: "hand.thumbsup.fill", title: "Like")
    static let hello = Reaction(id: .hello, duration: 5, userSpecific: true, iconName: "hand.wave.fill", title: "Hello")
    static let dislike = Reaction(id: .dislike, duration: 5, userSpecific: true, iconName: "hand.thumbsdown.fill", title: "Dislike")
    static let smile = Reaction(id: .smile, duration: 5, userSpecific: true, iconName: "face.smiling.fill", title: "Smile")
    static let heart = Reaction(id: .heart, duration: 5, userSpecific: true, iconName: "heart.fill", title: "Heart")
}
