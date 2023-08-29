//
//  Call+Identifiable.swift
//  DemoApp
//
//  Created by Ilias Pavlidakis on 29/8/23.
//

import Foundation
import StreamVideo

extension Call: Identifiable {
    public var id: String { cId }
}
