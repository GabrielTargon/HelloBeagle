//
//  HttpRequestBuilder.swift
//  HelloBeagle
//
//  Created by Marcos Jr on 31/05/21.
//

import Beagle
import Foundation

public class HttpRequestBuilder {

    public var additionalHeaders = [String: String]()
    
    public init() { }

    public func build(
        url: URL,
        requestType: Request.RequestType,
        additionalData: HttpAdditionalData?
    ) -> Result {
        
        if case .rawRequest(let requestData) = requestType {
            return Result(url, requestData)
        }
        
        var newUrl = url
        var body = additionalData?.httpData?.body

        let headers = makeHeaders(additionalData: additionalData)

        setupParametersFor(requestType: requestType, url: &newUrl, body: &body)

        return Result(
            url: newUrl,
            method: httpMethod(type: requestType, data: additionalData),
            headers: headers,
            body: body
        )
    }
    
    public struct Result {
        var url: URL
        var method: String
        var headers: [String: String]
        var body: Data?
        
        init(url: URL, method: String, headers: [String: String], body: Data?) {
            self.url = url
            self.method = method
            self.headers = headers
            self.body = body
        }
        
        init(_ url: URL, _ requestData: Request.RequestData) {
            let method = requestData.method ?? "GET"
            var body: Data?
            if method != "GET" {
                body = try? JSONSerialization.data(withJSONObject: requestData.body ?? [:], options: [.fragmentsAllowed])
            }
            self.init(url: url, method: method, headers: requestData.headers ?? [:], body: body)
        }

        func toUrlRequest() -> URLRequest {
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 100)
            request.httpMethod = method
            request.httpBody = body
            headers.forEach {
                request.addValue($0.value, forHTTPHeaderField: $0.key)
            }
            return request
        }
    }

    private func makeHeaders(additionalData: HttpAdditionalData?) -> [String: String] {
        var headers = [
            "Content-Type": "application/json",
            "beagle-platform": "IOS"
        ]
        additionalData?.headers.forEach {
            headers.updateValue($0.value, forKey: $0.key)
        }
        additionalHeaders.forEach {
            headers.updateValue($0.value, forKey: $0.key)
        }
        return headers
    }

    private func httpMethod(type: Request.RequestType, data: HttpAdditionalData?) -> String {
        switch (type, data) {

        case (.submitForm(let form), _):
            return form.method.rawValue
            
        case (.rawRequest(let requestData), _):
            return requestData.method ?? "GET"

        case (_, nil):
            return "GET"

        case (_, let data?):
            return data.httpData?.method.rawValue ?? "GET"
        }
    }

    private func setupParametersFor(
        requestType: Request.RequestType,
        url: inout URL,
        body: inout Data?
    ) {
        guard case .submitForm(let form) = requestType else { return }

        switch form.method {
        case .post, .put:
            configureBodyParameters(form.values, in: &body)

        case .get, .delete:
            configureURLParameters(form.values, in: &url)
        }
    }

    private func configureBodyParameters(
        _ parameters: [String: Any],
        in body: inout Data?
    ) {
        body = try? JSONSerialization.data(withJSONObject: parameters, options: [])
    }

    private func configureURLParameters(
        _ parameters: [String: String],
        in url: inout URL
    ) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        components.queryItems = parameters
            .filter { !$0.value.isEmpty }
            .map { URLQueryItem(name: $0.key, value: $0.value) }

        if let newUrl = components.url {
            url = newUrl
        }
    }
}
