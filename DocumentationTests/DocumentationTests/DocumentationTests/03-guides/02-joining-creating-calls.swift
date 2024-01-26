import StreamVideo

fileprivate func content() {
    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: "123")
        let result = try await call.create()
    }

    asyncContainer {
        let call = streamVideo.call(callType: "default", callId: "123")
        let result = try await call.join()
    }

    asyncContainer {
        // create
        let call = streamVideo.call(callType: "default", callId: "123")
        let result = try await call.create()

        // update
        let custom: [String: RawJSON] = ["secret": .string("secret")]
        let updateResult = try await call.update(custom: custom)

        // get
        let getResult = try await call.get()
    }

    asyncContainer {
        let members = ["thierry", "tommaso"]
        let call = streamVideo.call(callType: "default", callId: UUID().uuidString)

        let result = try await call.create(
            memberIds: members,
            custom: ["color": .string("red")],
            startsAt: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            team: "stream",
            ring: true,
            notify: false
        )
    }

    asyncContainer {
        let filters: [String: RawJSON] = ["user_id": .string("jaewoong")]
        let response = try await call.queryMembers(
            filters: filters,
            sort: [SortParamRequest.descending("created_at")],
            limit: 5
        )
    }
}
