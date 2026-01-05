//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum ImageFactory {
    
    static func get(_ number: Int) -> URL? {
        switch number {
        case 1:
            return Bundle.testResources.url(forResource: "olive", withExtension: "png")
        case 2:
            return Bundle.testResources.url(forResource: "coffee", withExtension: "png")
        case 3:
            return Bundle.testResources.url(forResource: "sky", withExtension: "png")
        case 4:
            return Bundle.testResources.url(forResource: "forest", withExtension: "png")
        case 5:
            return Bundle.testResources.url(forResource: "sun", withExtension: "png")
        case 6:
            return Bundle.testResources.url(forResource: "fire", withExtension: "png")
        case 7:
            return Bundle.testResources.url(forResource: "sea", withExtension: "png")
        case 8:
            return Bundle.testResources.url(forResource: "violet", withExtension: "png")
        case 9:
            return Bundle.testResources.url(forResource: "pink", withExtension: "png")
        default:
            return Bundle.testResources.url(forResource: "skin", withExtension: "png")
        }
    }
}
