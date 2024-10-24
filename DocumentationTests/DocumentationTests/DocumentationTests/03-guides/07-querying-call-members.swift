import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
    asyncContainer {
        // sorting and pagination
        let sort = SortParamRequest(direction: 1, field: "user_id")
        let result1 = try await call.queryMembers(
            sort: [sort],
            limit: 10
        )

        // loading the next page
        if let next = result1.next {
            let result2 = try await call.queryMembers(sort: [sort], limit: 10, next: next)
        }
                    
        // filtering
        let result2 = try await call.queryMembers(
            filters: ["role": .dictionary(["eq": "admin"])]
        )
    }
}
