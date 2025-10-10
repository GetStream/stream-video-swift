//
//  StoreCoordinator.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 10/10/25.
//

import Foundation

class StoreCoordinator<Namespace: StoreNamespace>: @unchecked Sendable {

    func shouldExecute(
        action: Namespace.Action,
        state: Namespace.State
    ) -> Bool {
        true
    }
}
