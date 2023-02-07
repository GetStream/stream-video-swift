//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal class EventsAPI {

    /**
     Send event
     
     - parameter type: (path)
     - parameter id: (path)
     - parameter sendEventRequest: (body)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - parameter completion: completion handler to receive the data and the error objects
     */
    @discardableResult
    internal class func sendEvent(
        type: String,
        id: String,
        sendEventRequest: SendEventRequest,
        apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue,
        completion: @escaping ((_ data: SendEventResponse?, _ error: Error?) -> Void)
    ) -> RequestTask {
        sendEventWithRequestBuilder(type: type, id: id, sendEventRequest: sendEventRequest).execute(apiResponseQueue) { result in
            switch result {
            case let .success(response):
                completion(response.body, nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
    }

    /**
     Send event
     - POST /call/{type}/{id}/event
     - Sends event to the call
     - API Key:
       - type: apiKey Authorization
       - name: JWT
     - API Key:
       - type: apiKey api_key (QUERY)
       - name: api_key
     - API Key:
       - type: apiKey Stream-Auth-Type
       - name: stream-auth-type
     - parameter type: (path)
     - parameter id: (path)
     - parameter sendEventRequest: (body)
     - returns: RequestBuilder<SendEventResponse>
     */
    internal class func sendEventWithRequestBuilder(
        type: String,
        id: String,
        sendEventRequest: SendEventRequest
    ) -> RequestBuilder<SendEventResponse> {
        var localVariablePath = "/call/{type}/{id}/event"
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        localVariablePath = localVariablePath.replacingOccurrences(
            of: "{type}",
            with: typePostEscape,
            options: .literal,
            range: nil
        )
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        localVariablePath = localVariablePath.replacingOccurrences(of: "{id}", with: idPostEscape, options: .literal, range: nil)
        let localVariableURLString = OpenAPIClientAPI.basePath + localVariablePath
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: sendEventRequest)

        let localVariableUrlComponents = URLComponents(string: localVariableURLString)

        let localVariableNillableHeaders: [String: Any?] = [
            :
        ]

        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)

        let localVariableRequestBuilder: RequestBuilder<SendEventResponse>.Type = OpenAPIClientAPI.requestBuilderFactory
            .getBuilder()

        return localVariableRequestBuilder.init(
            method: "POST",
            URLString: (localVariableUrlComponents?.string ?? localVariableURLString),
            parameters: localVariableParameters,
            headers: localVariableHeaderParameters,
            requiresAuthentication: true
        )
    }
}
